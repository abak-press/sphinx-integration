# frozen_string_literal: true
require "logger"

module Sphinx::Integration
  module HelperAdapters
    autoload :Base, 'sphinx/integration/helper_adapters/base'
    autoload :Local, 'sphinx/integration/helper_adapters/local'
    autoload :Remote, 'sphinx/integration/helper_adapters/remote'
  end

  class Helper
    SUCCESS = 'success'
    FAILURE = 'failure'
    private_constant :SUCCESS, :FAILURE

    %i(running? stop start suspend resume restart clean copy_config reload).each do |method_name|
      define_method(method_name) do
        begin
          log(method_name.to_s.capitalize)
          @sphinx.public_send(method_name)
        rescue StandardError => error
          log_error(error)
          raise
        end
      end
    end

    def initialize(options = {})
      ::ThinkingSphinx.context.define_indexes

      @options = options
      @options[:indexes] ||= []
      @logger = options[:logger]

      @indexes = ::ThinkingSphinx.
        indexes.
        select { |index| @options[:indexes].empty? || @options[:indexes].include?(index.name) }

      adapter_options = {logger: @logger, rotate: @options[:rotate]}

      @sphinx = options.fetch(:sphinx_adapter) do
        if config.remote?
          adapter_options[:host] = @options[:host]
          HelperAdapters::Remote.new(adapter_options)
        else
          HelperAdapters::Local.new(adapter_options)
        end
      end
    end

    def configure
      log "Configure sphinx"
      config.build(config.generated_config_file)
    rescue StandardError => error
      log_error(error)
      raise
    end

    def index
      log "Index sphinx"

      @indexes.each do |index|
        rotate_index = rotate? && index.rt?

        ::Sphinx::Integration::Mysql::Replayer.new(index.core_name).reset if rotate_index

        index.indexing(need_lock: rotate_index) do
          index.switch_rt if rotate_index

          @sphinx.index(index)

          index.last_indexing_time.write
        end

        if rotate_index
          ::Sphinx::Integration::ReplayerJob.enqueue(index.core_name)
        end
      end
      begin
        Rails.application.config.sphinx_integration.fetch(:send_index_notification).try(:call, SUCCESS)
      rescue StandardError => e
        log("Error while sending success notification. Error: #{e}")
      end
    rescue StandardError => error
      begin
        Rails.application.config.sphinx_integration.fetch(:send_index_notification).try(:call, FAILURE)
      rescue StandardError => e
        log("Error while sending failure notification. Error: #{e}")
      end
      log_error(error)
      raise
    end

    alias_method :reindex, :index

    def rebuild
      log "Rebuild sphinx"

      unless Sphinx::Integration.fetch(:rebuild, {})[:pass_sphinx_stop]
        stop rescue nil
      end

      clean
      configure
      copy_config
      index
      start
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

    def logger
      @logger ||= ::Sphinx::Integration.fetch(:di)[:loggers][:stdout].call
    end

    def notificator
      @notificator ||= ::Sphinx::Integration.fetch(:di)[:error_notificator]
    end
  end
end
