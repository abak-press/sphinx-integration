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

        def index_names
          ::ThinkingSphinx.indexes.map(&:core_name).join(" ")
        end

        def rotate?
          !!@options[:rotate]
        end
      end
    end
  end
end
