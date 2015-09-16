# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Configuration
      module DistributedIndex
        extend ActiveSupport::Concern

        included do
          attr_accessor :mirror_indices
          attr_accessor :persistent
          attr_writer :ha_strategy
          alias_method_chain :initialize, :integration
          alias_method_chain :valid?, :integration
          alias_method_chain :agent, :integration

          class << self
            alias_method_chain :settings, :integration
          end
        end

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

        def agents
          agents_list = agent_without_integration

          mirror_indices.each do |cluster|
            agents_list << cluster.map { |agent| "#{agent.remote}:#{agent.name}" }.join('|')
          end

          agents_list
        end

        def agent_with_integration
          return if persistent
          agents
        end

        def agent_persistent
          return unless persistent
          agents
        end

        module ClassMethods
          def settings_with_integration
            settings_without_integration + [:ha_strategy, :agent_persistent]
          end
        end

      end
    end
  end
end
