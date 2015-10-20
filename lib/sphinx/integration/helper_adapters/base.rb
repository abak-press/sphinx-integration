module Sphinx
  module Integration
    module HelperAdapters
      class Base
        delegate :log, to: 'ThinkingSphinx'

        def initialize(options = {})
          @options = options
        end

        private

        def config
          ThinkingSphinx::Configuration.instance
        end
      end
    end
  end
end
