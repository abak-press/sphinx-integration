module Sphinx
  module Integration
    module Extensions
      module ThinkingSphinx
        module Context
          extend ActiveSupport::Concern

          included do
            def load_models
              # nope
            end
          end
        end
      end
    end
  end
end
