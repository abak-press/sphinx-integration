# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Index::Builder
  class Join

    attr_accessor :index, :key

    # Создание =)
    #
    # index - ThinkingSphinx::Index
    # name - String or Hash{:table_name => :table_alias}
    def initialize(index, name)
      self.index = index

      if name.is_a?(Hash)
        table_name, table_alias = name.first
      else
        table_name, table_alias = name
      end

      self.key = table_alias || table_name

      index.local_options[:source_joins] ||= {}
      index.local_options[:source_joins][key] = {}
      index.local_options[:source_joins][key][:table_name] = table_name
      as(key)

      self
    end

    # Алиас для таблицы
    #
    # value - String or Symbol
    #
    # Returns self
    def as(value)
      index.local_options[:source_joins][key][:as] = value
      self
    end

    # Тип связи
    #
    # value - String or Symbol
    #
    # Returns self
    def type(value)
      index.local_options[:source_joins][key][:type] = value
      self
    end

    # По каким поля джойним
    #
    # value - String
    #
    # Returns self
    def on(value)
      index.local_options[:source_joins][key][:on] = value
      self
    end

    # Вместо таблички можно указать sql подзапрос
    #
    # value - String
    #
    # Returns self
    def query(value)
      index.local_options[:source_joins][key][:query] = value
      self
    end

  end
end