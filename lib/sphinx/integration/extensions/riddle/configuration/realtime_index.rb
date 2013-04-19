# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Configuration
      module RealtimeIndex
        extend ActiveSupport::Concern

        included do
          attr_accessor :rt_attr_multi
          alias_method_chain :initialize, :custom_fields

          class << self
            alias_method_chain :settings, :custom_fields
          end
        end

        def initialize_with_custom_fields(name)
          @rt_attr_multi = []
          initialize_without_custom_fields(name)
        end

        module ClassMethods
          def settings_with_custom_fields
            settings_without_custom_fields + [:rt_attr_multi]
          end
        end
      end
    end
  end
end