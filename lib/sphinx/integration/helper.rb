require "redis-mutex"
require "logger"

module Sphinx::Integration
  module HelperAdapters
    autoload :Base, 'sphinx/integration/helper_adapters/base'
    autoload :Local, 'sphinx/integration/helper_adapters/local'
    autoload :Remote, 'sphinx/integration/helper_adapters/remote'
  end

  class Helper
    MUTEX_EXPIRE = 10.hours

    include ::Sphinx::Integration::AutoInject.hash["logger.notificator", logger: "logger.stdout"]

    attr_reader :sphinx

    delegate :recent_rt, :mutex, to: 'self.class'
    delegate :indexes,
             :rt_indexes,
             to: '::ThinkingSphinx'

    [
      :running?, :stop, :start, :suspend, :resume, :restart,
      :remove_indexes, :remove_binlog, :copy_config, :reload
    ].each do |method_name|
      class_eval <<-EORUBY, __FILE__, __LINE__ + 1
        def #{method_name}
          log "#{method_name.capitalize}"
          sphinx.#{method_name}
        rescue => error
          log_error(error)
          raise
        end
      EORUBY
    end

    def self.full_reindex?
      mutex(:full_reindex).locked?
    end

    def self.log_updates?
      mutex(:log_updates).locked?
    end

    def self.online_indexing?
      mutex(:online_indexing).locked?
    end

    def self.mutex(name)
      @mutex ||= {}
      @mutex[name] ||= Redis::Mutex.new(name, expire: MUTEX_EXPIRE)
    end

    def self.recent_rt
      @recent_rt ||= Sphinx::Integration::RecentRt.new
    end

    def initialize(options = {})
      super

      ThinkingSphinx.context.define_indexes

      @options = options

      @sphinx = options.fetch(:sphinx_adapter) do
        if config.remote?
          HelperAdapters::Remote.new(options.slice(:host, :rotate).merge!(logger: logger))
        else
          HelperAdapters::Local.new(options.slice(:rotate).merge!(logger: logger))
        end
      end

      @mysql_client = options.fetch(:mysql_client) { config.mysql_client.dup }
    end

    def configure
      log "Configure sphinx"
      config.build(config.generated_config_file)
    rescue => error
      log_error(error)
      raise
    end

    def index
      log "Index sphinx"

      unless rotate?
        mutex(:full_reindex).with_lock { @sphinx.index }
        ThinkingSphinx.set_last_indexing_finish_time
        return
      end

      replayer.reset

      mutex(:online_indexing).with_lock do
        mutex(:full_reindex).with_lock do
          @sphinx.index
          recent_rt.switch
        end

        ThinkingSphinx.set_last_indexing_finish_time
        truncate_rt_indexes(recent_rt.prev)
        replayer.replay
      end
    rescue => error
      log_error(error)
      raise
    end

    alias_method :reindex, :index

    def rebuild
      log "Rebuild sphinx"

      stop rescue nil
      configure
      copy_config
      remove_indexes
      remove_binlog
      index
      start
    end

    # Очистить rt индексы
    #
    # Returns nothing
    def truncate_rt_indexes(partition = nil)
      log "Truncate rt indexes"

      rt_indexes.each do |index|
        log "- #{index.name}"

        if partition
          index.truncate(index.rt_name(partition))
        else
          index.truncate(index.rt_name(0))
          index.truncate(index.rt_name(1))
        end
      end
    end

    private

    def rotate?
      !!@options[:rotate]
    end

    def config
      @config ||= ThinkingSphinx::Configuration.instance
    end

    def replayer
      # TODO: Переиндексирование одной ноды без остановки редактирования еще не реализовано.
      #       Для этого здесь нужно выбирать правильного клиента в зависимости он переданного хоста в инициализатор.
      @replayer ||= ::Sphinx::Integration::Mysql::Replayer.new(mysql_client: @mysql_client, logger: logger)
    end

    def log(message, severity = ::Logger::INFO)
      message.to_s.split("\n").each { |m| logger.add(severity, m) }
    end

    def log_error(exception)
      logger.error(exception.message)
      logger.debug(exception.backtrace.join("\n")) if exception.backtrace
      notificator.call(exception.message)
    end
  end
end
