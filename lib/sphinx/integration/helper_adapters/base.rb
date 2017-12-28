module Sphinx
  module Integration
    module HelperAdapters
      class Base
        CORE_POSTFIX = 'core'.freeze

        include ::Sphinx::Integration::AutoInject.hash[logger: "logger.stdout"]

        def initialize(options = {})
          super

          @options = options
        end

        private

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
