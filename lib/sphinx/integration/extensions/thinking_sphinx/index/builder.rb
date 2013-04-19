# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Index::Builder

  autoload :Join, 'sphinx/integration/extensions/thinking_sphinx/index/builder/join'

  # Отменяет группировку по-умолчанию
  #
  # fields - String поля, по которым будем группировать
  def force_group_by(*fields)
    raise ArgumentError unless fields.any?
    source.groupings = fields
    set_property :force_group_by => true
  end
  alias_method :group_by!, :force_group_by

  # Задаёт лимит для выборки
  #
  # value - Integer
  def limit(value)
    set_property :sql_query_limit => value
  end

  # Блок, который будет вызывается при сохранении модели
  #
  # name - Symbol MVA attr name
  # block - должен возвращать массив для MVA атрибута
  # Yields Instance of ActiveRecord::Base
  def mva_attribute(name, &block)
    @index.mva_sources ||= {}
    @index.mva_sources[name] = block
  end

  # Формирует CTE (WITH _alias AS (SELECT ...))
  #
  # name - String
  def with(name)
    raise ArgumentError unless block_given?
    @index.local_options[:source_cte] ||= {}
    @index.local_options[:source_cte][name] = yield
  end

  # Формирует LEFT JOIN
  #
  # name - Symbol or Hash
  #        если Symbol, то это название таблицы
  #        если Hash, то это {:table_name => :alias}
  #
  # Returns Sphinx::Integration::Extensions::ThinkingSphinx::Index::Builder::Join
  def left_join(name)
    Join.new(@index, name).type(:left)
  end

  # Формирует INNER JOIN
  #
  # name - Symbol or Hash
  #        если Symbol, то это название таблицы
  #        если Hash, то это {:table_name => :alias}
  #
  # Returns Sphinx::Integration::Extensions::ThinkingSphinx::Index::Builder::Join
  def inner_join(name)
    Join.new(@index, name).type(:inner)
  end

  # Заменяет дефолтное название таблицы
  #
  # value - String
  def from(value)
    set_property :source_table => value
  end

  # Наполнение индекса из другой базы
  #
  # value - Boolean or String
  def slave(value)
    set_property :use_slave_db => value
  end

  # Отключение группировки GROUP BY, которая делается по-умолчанию
  #
  # value - Boolean (default: true)
  def no_grouping(value = true)
    set_property :source_no_grouping => value
  end

  # Отключение индексации пачками
  #
  # value - Boolean (default: true)
  def disable_range(value = true)
    set_property :disable_range => value
  end

  # Указание своих минимального и максимального предела индексации
  #
  # value - String
  #
  # Examples
  #
  #   query_range("SELECT 1::int, COALESCE(MAX(id), 1::int) FROM rubrics")
  #
  def query_range(value)
    set_property :sql_query_range => value
  end

  # Отключение подстановок в WHERE $start >= ? and $end <= ?
  #
  # value - Boolean (default: true)
  def use_own_sql_query_range(value = true)
    set_property :use_own_sql_query_range => value
  end

end