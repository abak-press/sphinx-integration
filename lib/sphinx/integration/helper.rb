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
    attr_reader :sphinx

    delegate :recent_rt, to: 'self.class'
    delegate :log, to: 'ThinkingSphinx'

    [:running?, :stop, :start, :remove_indexes, :remove_binlog, :copy_config, :reload].each do |method_name|
      class_eval <<-EORUBY, __FILE__, __LINE__ + 1
        def #{method_name}
          log "#{method_name.capitalize}" do
            sphinx.#{method_name}
          end
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
      ThinkingSphinx.context.define_indexes

      ThinkingSphinx.logger = ::Logger.new(Rails.root.join("log", "index.log")).tap do |logger|
        logger.formatter = ::Logger::Formatter.new
        logger.level = ::Logger::INFO
      end

      @sphinx = config.remote? ? HelperAdapters::Remote.new(options) : HelperAdapters::Local.new(options)
    end

    def restart
      stop
      start
    end

    def configure
      log "Configure sphinx" do
        config.build(config.generated_config_file)
      end
    end

    def index(online = true)
      reset_waste_records

      log "Index sphinx" do
        with_index_lock do
          @sphinx.index(online)
          recent_rt.switch if online
        end
      end

      ThinkingSphinx.set_last_indexing_finish_time

      return unless online

      truncate_rt_indexes(recent_rt.prev)
      cleanup_waste_records
    end
    alias_method :reindex, :index

    def rebuild
      with_updates_lock do
        stop rescue nil
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
    def truncate_rt_indexes(partition = nil)
      log "Truncate rt indexes"

      rt_indexes do |index|
        log "- #{index.name}" do
          if partition
            index.truncate(index.rt_name(partition))
          else
            index.truncate(index.rt_name(0))
            index.truncate(index.rt_name(1))
          end
        end
      end
    end

    private

    def reset_waste_records
      log "Reset waste records"

      rt_indexes do |index|
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

      rt_indexes do |index|
        waste_records = Sphinx::Integration::WasteRecords.for(index)
        log "- #{index.name} (#{waste_records.size} records)" do
          waste_records.cleanup
        end
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

    # Итератор по всем rt индексам
    #
    # Yields ThinkingSphinx::Index, ActiveRecord::Base
    def rt_indexes
      ThinkingSphinx.context.indexed_models.each do |model_name|
        model = model_name.constantize
        next unless model.rt_indexed_by_sphinx?

        model.sphinx_indexes.each do |index|
          yield index
        end
      end
    end
  end
end
