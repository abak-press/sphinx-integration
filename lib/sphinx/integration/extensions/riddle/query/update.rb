# coding: utf-8
require 'riddle/query/insert'

module Sphinx::Integration::Extensions
  module Riddle
    module Query
      class Update < ::Riddle::Query::Insert

        def initialize(index, fields, where)
          @index   = index
          @fields  = fields
          @where   = where
        end

        def to_sql
          "UPDATE #{@index} SET #{fields_to_s} WHERE #{where_to_s}"
        end

        private

        def fields_to_s
          @fields.map { |field, value| "#{field} = #{translated_value(value)}" }.join(', ')
        end

        def where_to_s
          if @where.is_a?(Hash)
            @where.map { |field, value| "#{field} = #{translated_value(value)}" }.join(' AND ')
          else
            @where.to_s
          end
        end

      end
    end
  end
end