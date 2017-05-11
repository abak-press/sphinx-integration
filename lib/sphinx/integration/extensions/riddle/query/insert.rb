# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Query
      module Insert
        extend ActiveSupport::Concern

        included do
          alias_method_chain :translated_value, :ext
        end

        # Riddle не совсем корректно обрабатывает все типы значений, например nil
        def translated_value_with_ext(value)
          value.nil? ? "''" : translated_value_without_ext(value)
        end
      end
    end
  end
end
