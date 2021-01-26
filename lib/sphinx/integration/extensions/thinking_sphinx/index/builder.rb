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

  # Блок, который будет вызываться при сохранении модели перед получением атрибутов из базы
  # С помощью него, можно подправить конечный sql
  def with_sql(options = {}, &block)
    @index.local_options[:with_sql] ||= {}
    @index.local_options[:with_sql][options.fetch(:on, :select)] = block
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

  # Удаляет CTE
  #
  # name - Список названий CTE - Symbol or String.
  #
  # Returns Array of Hash - опции удаленных CTE.
  def delete_withs(*names)
    names.map do |name|
      @index.local_options[:source_cte].delete(name)
    end
  end

  # Переименовывает CTE
  #
  # old_name - String, название сохранённого CTE
  # new_name - String, новое название CTE
  #
  # При перемещении новое CTE (если оно не было сохранено заранее) попадёт в конец списка CTE.
  # Можно указать то же название CTE, что переместит блок в конец списка CTE.
  #
  # Returns nothing
  def rename_with(old_name, new_name)
    with_block = @index.local_options[:source_cte].delete(old_name)
    @index.local_options[:source_cte][new_name] = with_block
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

  # Удаляет join(ы) из индекса
  #
  # name - Список названий джойнов - Symbol or String.
  #
  # Returns Array of Index::Builder::Join - массив удаленных join'ов или nil'ов.
  def delete_joins(*names)
    names.map do |name|
      @index.local_options[:source_joins].delete(name)
    end
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

  # Удаляет атрибут(ы) из индекса.
  #
  # names - Список названий атрибутов - Symbol or String.
  #
  # Returns Array of ThinkingSphinx::Attribute - массив удаленных атрибутов.
  def delete_attributes(*names)
    names.map do |name|
      attr = source.attributes.find { |attr| attr.alias.eql? name }
      source.attributes.delete(attr)
    end
  end

  # Удаляет полнотекстовые поля из индекса.
  #
  # names - Список названий полей - Symbol or String.
  #
  # Returns Array of ThinkingSphinx::Field - массив удаленных полей.
  def delete_fields(*names)
    names.map do |name|
      field = source.fields.find { |attr| attr.alias.eql? name }
      source.fields.delete(field)
    end
  end

  # Комбинирует несколько полей в одно(создает 1 общее поле в сфинксе),
  # позволяет делать запросы через составные поля композитного индекса.
  # В результатирующем запросе будет происходить подмена conditions.
  # Для генерации стабильных запросов и индексового запроса,
  # производится сортировка значений по названию составных полей.
  #
  # name - алиас
  # fields - определение составных частей индекса, могут быть использованы в conditions
  #
  # example:
  #   composite_index(:composite_idx, b_idx: "'b_1'", a_idx: "'a_2'")
  #
  #   Model.search conditions: {b_idx: "b_1 | b_2", a_idx: "a_2 | a_1"}
  #   # => select ... where ... MATCH('@composite_idx (a_2 | a_1) (b_1 | b_2)') ...
  def composite_index(name, fields)
    sorted_fields = Hash[fields.sort_by { |k, _v| k }]
    sql = "concat_ws(' ', #{sorted_fields.values.join(', ')})"

    composite_indexes = @index.local_options[:composite_indexes] ||= {}
    composite_indexes[name] = sorted_fields

    indexes sql, as: name
  end

  # Позволяет подменить части существующего композитного индекса
  def replace_composite_index_fields(name, fields)
    index_fields = @index.local_options
      .fetch(:composite_indexes)
      .fetch(name)

    delete_fields(name)

    composite_index(name, index_fields.merge!(fields))
  end
end
