# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Query
      module Select
        extend ActiveSupport::Concern

        included do
          alias_method_chain :filter_comparison_and_value, :integration
        end

        def reset_values
          @values = []
          self
        end

        def filter_comparison_and_value_with_integration(attribute, value)
          if value.respond_to?(:call)
            "#{escape_column(attribute)} #{value.call}"
          else
            filter_comparison_and_value_without_integration(attribute, value)
          end
        end
      end
    end
  end
end