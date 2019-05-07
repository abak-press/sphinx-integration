module Sphinx
  module Integration
    module HelperAdapters
      class Base
        CORE_POSTFIX = 'core'.freeze

        def initialize(options = {})
          @options = options
        end

        private

        def logger
          @logger = @options[:logger] || ::Sphinx::Integration.fetch(:di)[:loggers][:stdout].call
        end

        def config
          ThinkingSphinx::Configuration.instance
        end

        def rotate?
          !!@options[:rotate]
        end
      end
    end
  end
end
