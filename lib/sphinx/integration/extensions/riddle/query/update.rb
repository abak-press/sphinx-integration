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
          "UPDATE #{@index} SET #{fields_to_s} WHERE #{@where}"
        end

        private

        def fields_to_s
          (@fields.map do |field, value|
            "#{field} = #{translated_value(value)}"
          end).join(', ')
        end

      end
    end
  end
end