# coding: utf-8
require "redis-mutex"
require "logger"

module Sphinx::Integration
  module HelperAdapters
    autoload :Base, 'sphinx/integration/helper_adapters/base'
    autoload :Local, 'sphinx/integration/helper_adapters/local'
    autoload :Remote, 'sphinx/integration/helper_adapters/remote'
  end

  class Helper
    include ::Sphinx::Integration::AutoInject.hash["logger.notificator", logger: "logger.stdout"]

    attr_reader :sphinx

    delegate :recent_rt, to: 'self.class'
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
      Redis::Mutex.new(:full_reindex).locked?
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

      reset_waste_records

      with_index_lock do
        @sphinx.index
        recent_rt.switch if rotate?
      end

      ThinkingSphinx.set_last_indexing_finish_time

      return unless rotate?

      truncate_rt_indexes(recent_rt.prev)
      cleanup_waste_records
    rescue => error
      log_error(error)
      raise
    end

    alias_method :reindex, :index

    def rebuild
      log "Rebuild sphinx"

      with_updates_lock do
        stop rescue nil
        configure
        copy_config
        remove_indexes
        remove_binlog
        index
        start
      end
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

    def reset_waste_records
      log "Reset waste records"

      rt_indexes.each do |index|
        log "- #{index.name}" do
          Sphinx::Integration::WasteRecords.for(index).reset
        end
      end
    end

    def cleanup_waste_records
      log "Cleanup waste records"

      if Rails.env.production?
        log "sleep 120 sec"
        sleep 120
      end

      rt_indexes.each do |index|
        waste_records = Sphinx::Integration::WasteRecords.for(index)
        log "- #{index.name} (#{waste_records.size} records)"
        waste_records.cleanup
      end
    end

    def config
      ThinkingSphinx::Configuration.instance
    end

    # Установить блокировку на изменение данных в приложении
    #
    # Returns nothing
    def with_updates_lock
      Redis::Mutex.with_lock(:updates, expire: 10.hours) do
        yield
      end
    end

    def with_index_lock
      Redis::Mutex.with_lock(:full_reindex, expire: 10.hours) do
        yield
      end
    end

    def log(message, severity = ::Logger::INFO)
      message.to_s.split("\n").each { |m| logger.add(severity, m) }
    end

    def log_error(exception)
      logger.error(error.message)
      logger.debug(error.backtrace.join("\n"))
      notificator.call(error.message)
    end
  end
end
