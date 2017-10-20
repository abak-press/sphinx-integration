require 'redis-mutex'

module Sphinx::Integration
  class Transmitter
    PRIMARY_KEY = "sphinx_internal_id".freeze

    attr_reader :klass

    class_attribute :write_disabled

    delegate :full_reindex?, to: :'Sphinx::Integration::Helper'
    delegate :mysql_client, to: :"ThinkingSphinx::Configuration.instance"

    def initialize(klass)
      @klass = klass
    end

    # Обновляет запись в сфинксе
    #
    # record - ActiveRecord::Base
    #
    # Returns boolean
    def replace(record)
      return false if write_disabled?

      rt_indexes.each do |index|
        transmit(index, record)
      end

      true
    end

    # Удаляет запись из сфинкса
    #
    # record - ActiveRecord::Base
    #
    # Returns boolean
    def delete(record)
      return false if write_disabled?

      rt_indexes.each do |index|
        partitions { |partition| mysql_client.delete(index.rt_name(partition), record.sphinx_document_id) }

        mysql_client.soft_delete(index.core_name, record.sphinx_document_id)
      end

      true
    end

    # Обновление отдельных атрибутов записи
    #
    # record  - ActiveRecord::Base
    # data    - Hash (:field => :value)
    #
    # Returns nothing
    def update(record, data)
      return if write_disabled?

      update_fields(data, id: record.sphinx_document_id)
    end

    # Обновление отдельных атрибутов индекса по условию
    #
    # Массовое обновление колонок, при работающей полной переиндексации, может работать в двух режимах – `strict`.
    # В `строгом` режиме происходит полный перенос строк с помощью медленного replace из core в rt индексы. После
    # переиндексации строчка в core помечается как удаленная. То есть возможна временная достпуность и старых
    # и новых данных.
    # В `нестрогом` режиме обновление строк происходит с помощью быстрого update. После переиндексации
    # все эти обновления выполнятся вновь. То есть возможна временная недоуступность
    # новых данных. Это связано с тем, что indexer ротирует core индексы, тем самым в core могут быть старые значения,
    # а в rt обновляемых строк и вовсе не было.
    #
    # data      - Hash
    # :strict   - boolean (default: false). Строгость попадания данных в индекс во время индексации.
    # :matching - String
    # where     - Hash
    #
    # Returns nothing
    def update_fields(data, strict: false, matching: nil, **where)
      return if write_disabled?

      rt_indexes.each do |index|
        if full_reindex?
          partitions { |partition| mysql_client.update(index.rt_name(partition), data, matching: matching, **where) }

          if strict
            retransmit(index, matching: matching, **where)
          else
            mysql_client.update(index.core_name, data, matching: matching, **where)
          end
        else
          mysql_client.update(index.name, data, matching: matching, **where)
        end
      end
    end

    private

    # Запись объекта в rt index
    #
    # index  - ThinkingSphinx::Index
    # record - ActiveRecord::Base
    #
    # Returns nothing
    def transmit(index, record)
      data = transmitted_data(index, record)
      return unless data

      partitions { |partition| mysql_client.replace(index.rt_name(partition), data) }

      mysql_client.soft_delete(index.core_name, record.sphinx_document_id)
    end

    def transmit_all(index, ids)
      klass.where(id: ids).each { |record| transmit(index, record) }
    end

    # Перекладывает строчки из core в rt.
    #
    # index     - ThinkingSphinx::Index
    # :matching - String
    # where     - Hash
    #
    # Returns nothing
    def retransmit(index, matching: nil, **where)
      mysql_client.find_while_exists(index.core_name, PRIMARY_KEY, matching: matching, **where) do |rows|
        ids = rows.map { |row| row[PRIMARY_KEY].to_i }
        transmit_all(index, ids)
        sleep 0.1 # empirical throttle number
      end
    end

    # Данные, необходимые для записи в индекс сфинкса
    #
    # index  - ThinkingSphinx::Index
    # record - ActiveRecord::Base
    #
    # Returns Hash
    def transmitted_data(index, record)
      sql = index.single_query_sql.gsub('%{ID}', record.id.to_s)
      query_options = index.local_options[:with_sql]
      if (update_proc = query_options[:update]).respond_to?(:call)
        sql = update_proc.call(sql)
      end
      row = record.class.connection.execute(sql).first
      return unless row

      row.merge!(mva_attributes(index, record))

      row.each do |key, value|
        row[key] = case index.attributes_types_map[key]
                   when :integer then value.to_i
                   when :float then value.to_f
                   when :multi then type_cast_to_multi(value)
                   when :boolean then ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
                   else value
                   end
      end

      row
    end

    # MVA data
    #
    # index - ThinkingSphinx::Index
    #
    # Returns Hash
    def mva_attributes(index, record)
      attrs = {}

      index.mva_sources.each do |name, mva_proc|
        attrs[name] = mva_proc.call(record)
      end if index.mva_sources

      attrs
    end

    # RealTime индексы модели
    #
    # Returns Array
    def rt_indexes
      @rt_indexes ||= klass.sphinx_indexes.select(&:rt?)
    end

    # Итератор по текущим активным частям rt индексов
    #
    # Yields Integer
    def partitions
      if full_reindex?
        yield 0
        yield 1
      else
        yield Sphinx::Integration::Helper.recent_rt.current
      end
    end

    # Привести тип к мульти атрибуту
    #
    # value - NilClass or String or Array
    #
    # Returns Array
    def type_cast_to_multi(value)
      if value.nil?
        []
      elsif value.is_a?(String)
        value.split(',')
      else
        value
      end
    end
  end
end
