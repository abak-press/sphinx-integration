require "logger"

module Sphinx::Integration
  module HelperAdapters
    autoload :Base, 'sphinx/integration/helper_adapters/base'
    autoload :Local, 'sphinx/integration/helper_adapters/local'
    autoload :Remote, 'sphinx/integration/helper_adapters/remote'
  end

  class Helper
    include ::Sphinx::Integration::AutoInject.hash["logger.notificator", logger: "logger.stdout"]

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
      super

      ::ThinkingSphinx.context.define_indexes

      @options = options
      @options[:indexes] ||= []

      @indexes = ::ThinkingSphinx.
        indexes.
        select { |index| @options[:indexes].empty? || @options[:indexes].include?(index.name) }

      adapter_options = {logger: logger, rotate: @options[:rotate]}

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

      replayer.reset

      @indexes.each do |index|
        index.indexing do
          @sphinx.index(index.core_name)
          index.last_indexing_time.write

          if rotate? && index.rt?
            index.switch_rt
            replayer.replay
          end
        end
      end
    rescue StandardError => error
      log_error(error)
      raise
    end

    alias_method :reindex, :index

    def rebuild
      log "Rebuild sphinx"

      stop rescue nil
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

    def replayer
      @replayer ||= ::Sphinx::Integration::Mysql::Replayer.new(logger: logger)
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
