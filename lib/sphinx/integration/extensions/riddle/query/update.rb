# coding: utf-8
require 'riddle/query/insert'

module Sphinx::Integration::Extensions
  module Riddle
    module Query
      class Update < ::Riddle::Query::Insert

        def initialize(index, fields, where, matching)
          @index    = index
          @fields   = fields
          @where    = where
          @matching = matching
        end

        def to_sql
          "UPDATE #{@index} SET #{fields_to_s} WHERE #{combined_wheres}"
        end

        private

        def fields_to_s
          @fields.map { |field, value| "#{field} = #{translated_value(value)}" }.join(', ')
        end

        def combined_wheres
          wheres = where_to_s

          if @matching.nil?
            wheres
          elsif wheres.empty?
            "MATCH(#{::Riddle::Query.quote @matching})"
          else
            "MATCH(#{::Riddle::Query.quote @matching}) AND #{wheres}"
          end
        end

        def where_to_s
          if @where.is_a?(Hash)
            @where.map { |field, value| filter_comparison_and_value(field, value) }.join(' AND ')
          else
            @where.to_s
          end
        end

        def filter_comparison_and_value(attribute, value)
          case value
          when Array
            "#{escape_column(attribute)} IN (#{value.collect { |val| translated_value(val) }.join(', ')})"
          when Range
            "#{escape_column(attribute)} BETWEEN #{translated_value(value.first)} AND #{translated_value(value.last)}"
          else
            "#{escape_column(attribute)} = #{translated_value(value)}"
          end
        end

        def escape_column(column)
          if column.to_s =~ /\A[`@]/
            column
          else
            column_name, *extra = column.to_s.split(' ')
            extra.unshift("`#{column_name}`").compact.join(' ')
          end
        end

      end
    end
  end
end