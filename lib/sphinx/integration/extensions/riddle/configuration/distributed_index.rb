# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Configuration
      module DistributedIndex
        extend ActiveSupport::Concern

        included do
          attr_accessor :mirror_indices
          attr_writer :ha_strategy
          alias_method_chain :initialize, :integration
          alias_method_chain :valid?, :integration
          alias_method_chain :agent, :integration

          class << self
            alias_method_chain :settings, :integration
          end
        end

        module InstanceMethods
          def initialize_with_integration(name)
            initialize_without_integration(name)
            @mirror_indices = []
          end

          def valid_with_integration?
            local_indices.any? || remote_indices.any? || mirror_indices.any?
          end

          def ha_strategy
            @ha_strategy if mirror_indices.any?
          end

          def agent_with_integration
            agents = agent_without_integration

            mirror_indices.each do |cluster|
              agents << cluster.map { |agent| "#{agent.remote}:#{agent.name}" }.join('|')
            end

            agents
          end
        end

        module ClassMethods
          def settings_with_integration
            settings_without_integration + [:ha_strategy]
          end
        end

      end
    end
  end
end