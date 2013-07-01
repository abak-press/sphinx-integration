# coding: utf-8
module Sphinx::Integration
  class Helper
    module ClassMethods

      def config
        ThinkingSphinx::Configuration.instance
      end

      def sphinx_running?
        if config.remote?
          `#{Rails.root}/script/sphinx --status`.present?
        else
          ThinkingSphinx.sphinx_running?
        end
      end

      def run_command(command)
        puts "System: #{command}"
        system command
      end

      def stop
        if config.remote?
          run_command("#{Rails.root}/script/sphinx --stop")
        else
          run_command "searchd --config #{config.config_file} --stop"
        end
      end

      def start
        if config.remote?
          run_command("#{Rails.root}/script/sphinx --start")
        else
          run_command "searchd --config #{config.config_file}"
        end
      end

      def running_start
        stop if sphinx_running?
        start
      end

      # Переиндексация сфинкса
      #
      # online - Boolean (default: true) означает, что в момент индексации все апдейты будут писаться в дельту
      def index(online = true)
        Redis::Mutex.with_lock(:full_reindex, :expire => 3.hours) do
          if config.remote?
            run_command("#{Rails.root}/script/sphinx --reindex-offline") unless online
            run_command("#{Rails.root}/script/sphinx --reindex-online")  if  online
          else
            run_command "indexer --config #{config.config_file} --all" unless online
            run_command "indexer --config #{config.config_file} --rotate --all" if online
          end
        end

        prepare_rt if online
      end
      alias_method :reindex, :index

      # Очистить и Заполнить rt индексы
      #
      # only_index - String (default: nil) работать только с одним индексом
      def prepare_rt(only_index = nil)
        rt_indexes do |index, model|
          next if only_index && only_index != index.name

          truncate_rt_index(index.rt_name)

          dump_delta_index(model, index)
          truncate_rt_index(index.delta_rt_name)
        end
      end

      # Перенос данных из дельта индекса в основной
      #
      # model - ActiveRecord::Base
      # index - ThinkingSphinx::Index
      def dump_delta_index(model, index)
        delta_index_results(model, index) do |sphinx_result|
          model.where(model.primary_key => sphinx_result.to_a).each(&:transmitter_update)

          # Удаление через внутренний айдишник индекса, ибо пока сфинкс не умеет удалять по условию с другими атрибутами
          doc_ids = sphinx_result.results[:matches].map{ |x| x[:doc] }
          query = Riddle::Query::Delete.new(index.delta_rt_name, doc_ids)
          ThinkingSphinx.take_connection{ |c| c.execute(query.to_sql) }
        end
      end

      # Очистка rt индекса
      #
      # index_name - String
      def truncate_rt_index(index_name)
        ThinkingSphinx.take_connection { |c| c.execute("TRUNCATE RTINDEX #{index_name}") }
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

      # Уничтожить все индексы
      def remove_indexes
        if config.remote?
          run_command("#{Rails.root}/script/sphinx --remove-indexes")
        else
          FileUtils.rm(Dir.glob(config.searchd_file_path + '/*.*'))
        end
      end

      # Уничтожить бинарный лог
      def remove_binlog
        if (binlog_path = config.configuration.searchd.binlog_path).present?
          if config.remote?
            run_command("#{Rails.root}/script/sphinx --remove-binlog")
          else
            FileUtils.rm(Dir[binlog_path + '/*.*'])
          end
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

      def configure
        puts "Generating Configuration to #{config.config_file}"
        config.build
      end

      def rebuild
        configure

        if config.remote?
          run_command("#{Rails.root}/script/sphinx --copy-config #{config.config_file}")
        end

        stop if sphinx_running?
        remove_indexes
        remove_binlog
        index(false)
        start
      end

      def full_reindex?
        Redis::Mutex.new(:full_reindex).locked?
      end

    end

    extend ClassMethods
  end
end
