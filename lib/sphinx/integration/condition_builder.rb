# coding: utf-8
module Sphinx
  module Integration
    class ConditionBuilder
      # Генерирует условие запроса в форме строки
      #
      # condition - Hash
      #
      # Returns string
      def self.build(condition)
        result = []

        condition.each do |attribute, values|
          result << Condition.new(attribute, values).to_s
        end

        result.join(' AND ')
      end

      private
      class Condition
        def initialize(attribute, values)
          @attribute = attribute
          @values = Array(values)

          normalize_values
        end

        # Конвертация условия в строку
        #
        # Returns string
        def to_s
          if single_value?
            "#@attribute = #{@values.first}"
          else
            "#@attribute in (#{@values.join(', ')})"
          end
        end

        private
        def normalize_values
          @values.map! { |v| ::ActiveRecord::Base.quote_value(v) }
        end

        # Единственное значение аттрибута?
        #
        #  Returns boolean
        def single_value?
          @values.length == 1
        end
      end
    end
  end
end
