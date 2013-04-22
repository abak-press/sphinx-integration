# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Query
      module Insert
        extend ActiveSupport::Concern

        included do
          alias_method_chain :translated_value, :ext
        end

        # Riddle не совсем корректно обрабатывает все типы значений, например nil или Array
        def translated_value_with_ext(value)
          if value.nil?
            "''"
          elsif value.is_a?(Array)
            "(#{value.join(',')})"
          else
            translated_value_without_ext(value)
          end
        end

      end
    end
  end
end