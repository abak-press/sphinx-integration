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

    delegate :recent_rt, to: 'self.class'
    delegate :indexes,
             :rt_indexes,
             to: '::ThinkingSphinx'
    delegate :query_log, :mysql_client, to: :"ThinkingSphinx::Configuration.instance"

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

    def self.log_core_updates?
      mutex(:log_core_updates).locked?
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

      @sphinx = if config.remote?
                  HelperAdapters::Remote.new(options.slice(:host, :rotate).merge!(logger: logger))
                else
                  HelperAdapters::Local.new(options.slice(:rotate).merge!(logger: logger))
                end
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

      start_query_log(only_core_updates: true) if rotate?

      self.class.mutex(:full_reindex).with_lock do
        @sphinx.index
        recent_rt.switch if rotate?
      end

      ThinkingSphinx.set_last_indexing_finish_time

      return unless rotate?

      truncate_rt_indexes(recent_rt.prev)
      replay_query_log
    rescue => error
      finish_query_log if rotate?
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

    def start_query_log(only_core_updates: false)
      log "Start writing#{' only core' if only_core_updates} queries"
      reset_query_log
      self.class.mutex(:log_updates).unlock(true)
      self.class.mutex(:log_core_updates).unlock(true)
      mutex_name = only_core_updates ? :log_core_updates : :log_updates
      self.class.mutex(mutex_name).lock!
    end

    def finish_query_log
      log "Finish writing queries"
      self.class.mutex(:log_updates).unlock(true)
      self.class.mutex(:log_core_updates).unlock(true)
    end

    def replay_query_log
      log "Replay queries. count: #{query_log.size}"

      query_log.each do |query|
        mysql_client.write(query, log_query: false)
      end

      finish_query_log
      reset_query_log
    end

    def reset_query_log
      log "Reset query log"
      query_log.reset
    end

    private

    def rotate?
      !!@options[:rotate]
    end

    def config
      @config ||= ThinkingSphinx::Configuration.instance
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
