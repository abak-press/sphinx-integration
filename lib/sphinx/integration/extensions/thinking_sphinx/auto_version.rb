module Sphinx
  module Integration
    module Extensions
      module ThinkingSphinx
        module AutoVersion
          extend ActiveSupport::Concern

          included do
            class << self
              alias_method_chain :detect, :integration
            end
          end

          module ClassMethods
            def detect_with_integration
              version = ::ThinkingSphinx::Configuration.instance.version
              if version =~ /2.2.\d/
                require 'riddle/2.1.0'
              else
                detect_without_integration
              end
            end
          end
        end
      end
    end
  end
end
