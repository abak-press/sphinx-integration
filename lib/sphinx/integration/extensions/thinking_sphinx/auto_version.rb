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

              case version
              when '0.9.8', '0.9.9'
                require "riddle/#{version}"
              when /1.10/
                require 'riddle/1.10'
              when /2.0.[12]/
                require 'riddle/2.0.1'
              else
                require 'riddle/2.1.0'
              end
            end
          end
        end
      end
    end
  end
end
