module Sphinx::Integration
  class Transmitter
    PRIMARY_KEY = "sphinx_internal_id".freeze
    TEMPLATE_ID = '%{ID}'.freeze

    attr_reader :klass

    class_attribute :write_disabled

    def initialize(klass)
      @klass = klass
    end

    # Public: Получение буферизированного трансмиттера
    #
    # options - Hash опции Sphinx::Integration::BufferedTransmitter
    #
    # Returns Sphinx::Integration::BufferedTransmitter
    def buffered(options = {})
      BufferedTransmitter.new(self, options)
    end

    # Public: Выполняет отложенное действие в сфинксе
    #
    # action  - Symbol (:replace, :delete supported)
    # records - Array of Integer | Array of AR instances
    #
    # Returns String job meta id
    def enqueue_action(action, records)
      TransmitterJob.enqueue(klass.to_s, action, record_ids(records))
    end

    # Обновляет записи в сфинксе
    #
    # records - Array of Integer | Array of AR instances
    #
    # Returns boolean
    def replace(records)
      return false if write_disabled?

      rt_indexes.each { |index| transmit(index, Array(records)) }

      true
    end

    # Удаляет записи из сфинкса
    #
    # records - Array of Integer
    #
    # Returns boolean
    def delete(records)
      return false if write_disabled?

      ids = sphinx_document_ids(record_ids(records))

      rt_indexes.each do |index|
        index.rt.delete(ids)
        index.plain.soft_delete(ids)
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
    # Массовое обновление колонок, при работающей полной переиндексации работает по следующей схеме.
    # Во время индексации запросы записываются в лог. После переиндексации
    # все эти обновления выполнятся вновь. То есть возможна временная недоуступность
    # новых данных (максимум пару минут). Это связано с тем, что indexer ротирует core индексы,
    # тем самым в core могут быть старые значения, а в rt обновляемых строк и вовсе не было.
    #
    # data      - Hash
    # :matching - NilClass or String or Hash of [Symbol, String]
    # where     - Hash
    #
    # Returns nothing
    def update_fields(data, matching: nil, **where)
      return if write_disabled?

      rt_indexes.each do |index|
        if index.indexing?
          # Вначале обновим все что уже есть в rt.
          index.rt.update(data, matching: matching, where: where)
          # Обновим всё в core и этот запрос запишется в query log, который потом повторится после ротации.
          index.plain.update(data, matching: matching, where: where)
        else
          index.distributed.update(data, matching: matching, where: where)
        end
      end
    end

    private

    # Запись объектов в rt index
    #
    # index  - ThinkingSphinx::Index
    # records - Array of Integer | Array of AR instances
    #
    # Returns nothing
    def transmit(index, records)
      data = transmitted_data(index, records)
      return unless data

      index.rt.replace(data)
      index.plain.soft_delete(sphinx_document_ids(records))
    end
    alias transmit_all transmit

    # Перекладывает строчки из core в rt.
    #
    # index     - ThinkingSphinx::Index
    # :matching - String
    # where     - Hash
    #
    # Returns nothing
    def retransmit(index, matching: nil, where: {})
      index.plain.find_while_exists(PRIMARY_KEY, matching: matching, where: where) do |rows|
        ids = rows.map { |row| row[PRIMARY_KEY].to_i }
        transmit(index, ids)
        sleep 0.1 # empirical throttle number
      end
    end

    # Данные, необходимые для записи в индекс сфинкса
    #
    # index  - ThinkingSphinx::Index
    # records - Array of Integer | Array of AR instances
    #
    # Returns Hash
    def transmitted_data(index, records)
      check_instance_records(records) if need_instance_records?

      rows = connection.select_all(prepared_sql(index, records))

      rows.map! do |row|
        if need_instance_records?
          record = records.find { |r| r.id == row['sphinx_internal_id'].to_i }
          row.merge!(mva_attributes(index, record))
        end

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
    end

    def prepared_sql(index, records)
      sql = index.query_sql.gsub(/LIMIT [0-9]+$/, '')
      convert_sql_conditions!(sql, record_ids(records))

      query_options = index.local_options[:with_sql]
      if query_options && (update_proc = query_options[:update]).respond_to?(:call)
        sql = update_proc.call(sql)
      end

      sql
    end

    def convert_sql_conditions!(sql, record_ids)
      ids = if record_ids.length > 1
              sql.gsub!(/>= \$start.*?\$end/, "= ANY(ARRAY[#{TEMPLATE_ID}])")
              record_ids.join(',')
            else
              sql.gsub!(/>= \$start.*?\$end/, "= #{TEMPLATE_ID}")
              sql << ' LIMIT 1'
              record_ids.first
            end

      sql.gsub!(TEMPLATE_ID, ids.to_s)

      sql
    end

    # MVA data
    #
    # index - ThinkingSphinx::Index
    #
    # Returns Hash
    def mva_attributes(index, record)
      return {} if index.mva_sources.blank?

      index.mva_sources.each_with_object({}) do |(name, mva_proc), attrs|
        attrs[name] = mva_proc.call(record)
      end
    end

    # RealTime индексы модели
    #
    # Returns Array
    def rt_indexes
      @rt_indexes ||= klass.sphinx_indexes.select(&:rt?)
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

    ##
    # коннекция к бд
    #

    def connection
      klass.connection
    end

    def sphinx_document_ids(records)
      records.map do |item|
        if item.respond_to?(:sphinx_document_id)
          item.sphinx_document_id
        else
          item * ::ThinkingSphinx.context.indexed_models.size + klass.sphinx_offset
        end
      end
    end

    def check_instance_records(records)
      Array(records).each { |item| raise "instance of #{klass} needed" unless item.is_a?(klass) }
    end

    def record_ids(records)
      Array(records).map { |item| item.respond_to?(:id) ? item.id : item }
    end

    ##
    # Если определен mva_sources на индексе, то
    # требуется массив инстансов модели класса klass, так как proc на mva_sources работает
    # с инстансем
    #

    def need_instance_records?
      return @_need_instance_records if defined?(@_need_instance_records)

      @_need_instance_records = rt_indexes.any? { |index| index.mva_sources.present? }
    end
  end
end
