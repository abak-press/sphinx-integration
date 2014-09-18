# coding: utf-8
require 'rye'
require 'redis-mutex'

module Sphinx::Integration
  class Helper

    MAX_FULL_REINDEX_LOCK_TIME = 6.hours
    CONFIG_PATH = 'conf/sphinx.conf'.freeze
    REINDEX_CONFIG_PATH = 'conf/sphinx.reindex.conf'.freeze

    attr_reader :node
    attr_reader :master
    attr_reader :agents
    attr_reader :nodes

    def self.full_reindex?
      Redis::Mutex.new(:full_reindex).locked?
    end

    def initialize(node = nil)
      node = node.presence || 'all'

      if config.replication? && !config.remote?
        raise 'Support for replication only remote!'
      end

      if config.remote? && config.configuration.searchd.remote_path.nil?
        raise 'Config remote_path should be spicified!'
      end

      @node = ActiveSupport::StringInquirer.new(node)

      init_ssh if config.remote?
    end

    # Запущен ли сфинкс?
    #
    # Returns boolean
    def sphinx_running?
      if config.remote?
        begin
          nodes.searchd('--status')
        rescue Rye::Err
          false
        end
      else
        ThinkingSphinx.sphinx_running?
      end
    end

    # Остновить сфинкс
    #
    # Returns nothing
    def stop
      if config.remote?
        nodes.searchd('--stopwait')
      else
        local_searchd('--stopwait')
      end
    end

    # Запустить сфинкс
    #
    # Returns nothing
    def start
      if config.remote?
        nodes.searchd
      else
        local_searchd
      end
    end

    # Перезапустить сфинкс
    #
    # Returns nothing
    def restart
      stop
      sleep 1
      start
    end

    # Построить конфиги для сфинкса
    #
    # Returns nothing
    def configure
      config.build
    end

    # Уничтожить все индексы
    #
    # Returns nothing
    def remove_indexes
      puts "Removing indexes:"

      if config.remote?
        nodes.remove_indexes
      else
        files = Dir.glob("#{config.searchd_file_path}/*.*")
        puts files.join("\n")
        FileUtils.rm(files)
      end
    end

    # Уничтожить бинарный лог
    #
    # Returns nothing
    def remove_binlog
      if (binlog_path = config.configuration.searchd.binlog_path).present?
        puts "Removing binlog:"

        if config.remote?
          nodes.remove_binlog
        else
          files = Dir.glob("#{config.searchd_file_path}/*.*")
          puts files.join("\n")
          FileUtils.rm(Dir.glob("#{binlog_path}/*.*"))
        end
      end
    end

    # Скопировать конфиги на сервер(ы)
    #
    # Returns nothing
    def copy_config
      return unless config.remote?

      master_remote_path = config.configuration.searchd.remote_path

      if config.replication?
        if node.all? || node.master?
          config.agents.each do |_, agent|
            remote_config_path = agent.fetch(:remote_path, master_remote_path).join(CONFIG_PATH)
            agent[:box].file_upload(config.config_file(:slave, agent), remote_config_path)
          end if node.all?

          master.file_upload(config.config_file(:master), master_remote_path.join(CONFIG_PATH))
        else
          nodes.boxes.each do |box|
            _, agent = config.agents.detect { |_, agent| agent[:box] == box }
            remote_config_path = agent.fetch(:remote_path, master_remote_path).join(CONFIG_PATH)
            box.file_upload(config.config_file(:slave, agent), remote_config_path)
          end
        end
      else
        master.file_upload(config.config_file(:single), master_remote_path.join(CONFIG_PATH))
      end
    end

    # Переиндексация сфинкса
    #
    # online - boolean (default: true) означает, что в момент индексации все апдейты будут писаться в дельту
    def index(online = true)
      raise 'Мастер ноду нельзя индексировать' if node.master?
      puts "Start indexing"
      indexer_args = []
      indexer_args << '--rotate' if online

      if config.remote?
        indexer_args << "--config %REMOTE_PATH%/#{CONFIG_PATH}"
        if config.replication?
          if node.all?
            full_reindex_with_replication(online)
          else
            with_index_lock { nodes.indexer(indexer_args) }
            catch_up_indexes(:truncate => false) if online
          end
        else
          with_index_lock { master.indexer(indexer_args) }
          catch_up_indexes if online
        end
      else
        with_index_lock { local_indexer(indexer_args) }
        catch_up_indexes if online
      end

      ThinkingSphinx.set_last_indexing_finish_time
    end
    alias_method :reindex, :index

    # Полное перестроение с нуля
    #
    # Returns nothing
    def rebuild
      with_updates_lock do
        stop
        configure
        copy_config
        remove_indexes
        remove_binlog
        index(false)
        start
      end
    end

    # Очистить rt индексы
    #
    # Returns nothing
    def truncate_rt_indexes
      rt_indexes do |index, model|
        index.truncate(index.rt_name)
        index.truncate(index.delta_rt_name)
      end
    end

    protected

    # Инициализация Rye - which run SSH commands on a bunch of machines at the same time
    #
    # Returns nothing
    def init_ssh
      add_commands

      @master = Rye::Box.new(config.address, ssh_options)
      @master.pre_command_hook = proc do |cmd, *_|
        cmd.gsub!('%REMOTE_PATH%', config.configuration.searchd.remote_path.cleanpath.to_s)
        ::Kernel.puts "$ #{cmd}"
      end
      @master.stdout_hook = proc { |data| ::Kernel.puts data.to_s }

      @nodes = Rye::Set.new('nodes', ssh_options.merge(:parallel => true))

      if config.replication?
        @agents = Rye::Set.new('agents', ssh_options)

        config.agents.each do |name, agent|
          agent[:box] = Rye::Box.new(agent[:address], ssh_options)
          agent[:box].pre_command_hook = proc do |cmd, *_|
            remote_path = agent.fetch(:remote_path, config.configuration.searchd.remote_path)
            cmd.gsub!('%REMOTE_PATH%', remote_path.cleanpath.to_s)
            ::Kernel.puts "$ #{cmd}"
          end
          agent[:box].stdout_hook = proc { |data| ::Kernel.puts data.to_s }
          agents.add_box(agent[:box])
          nodes.add_box(agent[:box]) if node.all? || node == name
        end
      end

      nodes.add_box(master) if node.all? || node.master?
    end

    # Опции подключения для Rye
    #
    # Returns Hash
    def ssh_options
      {
        :quiet => false,
        :info => true,
        :safe => false,
        :user => config.user,
        :debug => false
      }
    end

    # Добавление комманд Rye, которые будут запускаться удалённо
    #
    # Returns nothing
    def add_commands
      Rye::Cmd.add_command :searchd, 'searchd', "--config %REMOTE_PATH%/#{CONFIG_PATH}"
      Rye::Cmd.add_command :indexer, 'indexer', "--all"
      Rye::Cmd.add_command :remove_indexes, 'rm', "-f %REMOTE_PATH%/#{config.searchd_file_path(false)}/*"
      Rye::Cmd.add_command :remove_binlog, 'rm', "-f %REMOTE_PATH%/#{config.configuration.searchd.binlog_path(false)}/*"
    end

    # Полня переиндексация всего кластера
    #
    # online - boolean
    #
    # Returns nothing
    def full_reindex_with_replication(online = true)
      with_index_lock do
        main_box = agents.boxes.shift
        main_agent = config.agents.detect { |_, x| x[:box] == main_box }.last

        if online
          # При онлайн индексации нужно сгенерировать индексные файлы, с опцией --rotate они сразу подменятся
          # и потом скопировать их на другие слевый будет невозможно (так пробовал, но другие слейвы падали в сегфолт).
          # Поэтому делаем новую конфигу для индексатора, в которой пути для индексных файлов будут иметь суффикс .new.
          # которые мы потом копируем на все слейвы и посылаем SIGHUP всем сфинксам
          # По этому сигналу сфинкс ищет индексные файлы с таким префиксом и переключается на них, переименовывая их.
          main_box.execute("cat %REMOTE_PATH%/#{CONFIG_PATH} | sed -e '/data\\//s/_core/_core.new/g' > %REMOTE_PATH%/#{REINDEX_CONFIG_PATH}")
          main_box.indexer("--config %REMOTE_PATH%/#{REINDEX_CONFIG_PATH}")
          main_box.rm("%REMOTE_PATH%/#{REINDEX_CONFIG_PATH}")
        else
          main_box.indexer("--config %REMOTE_PATH%/#{CONFIG_PATH}")
        end

        data_path = Pathname.new(config.searchd_file_path(false)).cleanpath.to_s
        main_agent_remote_path = main_agent.fetch(:remote_path, config.configuration.searchd.remote_path)
        source_path = main_agent_remote_path.join(data_path, "*#{'.new.*' if online}")
        main_ssh_credentials = "#{main_box.user}@#{main_box.host}"
        agents.execute("rsync -lptv #{main_ssh_credentials}:#{source_path} %REMOTE_PATH%/#{data_path}/")
        agents.boxes.unshift(main_box)
        agents.kill("-SIGHUP `cat %REMOTE_PATH%/#{config.configuration.searchd.pid_file(false)}`") if online
      end

      catch_up_indexes if online
    end

    # Нагнать rt индексы данными, которые лежат в delta rt
    #
    # options - Hash
    #           :truncate - boolean очищать ли rt индекс (default: true)
    #
    # Returns nothing
    def catch_up_indexes(options = {})
      options = options.reverse_merge(:truncate => true)

      rt_indexes do |index, model|
        index.truncate(index.rt_name) if options[:truncate]
        dump_delta_index(model, index)
        index.truncate(index.delta_rt_name)
      end
    end

    # Перенос данных из дельта индекса в основной
    #
    # model - ActiveRecord::Base
    # index - ThinkingSphinx::Index
    #
    # Returns nothing
    def dump_delta_index(model, index)
      delta_index_results(model, index) do |sphinx_result|
        model.where(model.primary_key => sphinx_result.to_a).each(&:transmitter_update)

        # Удаление через внутренний айдишник индекса, ибо пока сфинкс не умеет удалять по условию с другими атрибутами
        doc_ids = sphinx_result.results[:matches].map{ |x| x[:doc] }
        query = Riddle::Query::Delete.new(index.delta_rt_name, doc_ids)
        ThinkingSphinx.take_connection { |c| c.execute(query.to_sql) }
      end
    end

    private

    def config
      ThinkingSphinx::Configuration.instance
    end

    def local_searchd(*params)
      puts Rye.shell(:searchd, "--config #{config.config_file(:single)}", *params).inspect
    end

    def local_indexer(*params)
      puts Rye.shell(:indexer, "--config #{config.config_file(:single)} --all", *params).inspect
    end

    # Установить блокировку на индексацию
    #
    # Returns nothing
    def with_index_lock
      Redis::Mutex.with_lock(:full_reindex, :expire => MAX_FULL_REINDEX_LOCK_TIME) do
        yield
      end
    end

    # Установить блокировку на изменение данных в приложении
    #
    # Returns nothing
    def with_updates_lock
      Redis::Mutex.with_lock(:updates, :expire => MAX_FULL_REINDEX_LOCK_TIME) do
        yield
      end
    end

    # Итератор по всем rt индексам
    #
    # Yields ThinkingSphinx::Index, ActiveRecord::Base
    def rt_indexes
      ThinkingSphinx.context.indexed_models.each do |model_name|
        model = model_name.constantize
        next unless model.rt_indexed_by_sphinx?

        model.sphinx_indexes.each do |index|
          yield index, model
        end
      end
    end

    # Итератор по всем данным дельта индекса, отдаётся пачками по limit штук
    #
    # model - ActiveRecord::Base
    # index - ThinkingSphinx::Index
    # limit - Integer (default: 500)
    #
    # Yields ThinkingSphinx::Search
    def delta_index_results(model, index, limit = 500)
      until model.search_count(:index => index.delta_rt_name).zero? do
        yield model.search_for_ids(:index => index.delta_rt_name, :per_page => limit)
      end
    end

  end
end
