module Sphinx::Integration
  class Transmitter
    PRIMARY_KEY = "sphinx_internal_id".freeze
    TRANSMIT_BATCH_SIZE = 100
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
        index.core.soft_delete(ids)

        if index.indexing?
          index.plain.soft_delete(ids)
          prev_rt_delete(index, ids)
        end
      end

      true
    end

    # TODO: удалить
    def update(record, data)
      return if write_disabled?

      update_fields(data, id: record.sphinx_document_id)
    end
    deprecate :update

    # TODO: удалить
    def update_fields(data, matching: nil, **where)
      return if write_disabled?

      primary_keys = Array.wrap(where.with_indifferent_access[PRIMARY_KEY])

      if primary_keys.present?
        rt_indexes.each do |index|
          transmit(index, primary_keys)
        end
      else
        replace_all(matching: matching, where: where)
      end
    end
    deprecate :update_fields

    # Запись объектов в rt index по условию
    #
    # :matching - String
    # where     - Hash
    #
    # Returns nothing
    def replace_all(matching: nil, where: {})
      return if write_disabled?

      raise ArgumentError.new('Use replace with primary keys') if where.with_indifferent_access[PRIMARY_KEY]

      rt_indexes.each do |index|
        index.distributed.find_in_batches(
          primary_key: PRIMARY_KEY,
          batch_size: TRANSMIT_BATCH_SIZE,
          matching: matching,
          where: where
        ) do |rows|
          ids = rows.map { |row| row[PRIMARY_KEY].to_i }
          transmit(index, ids)
        end
      end
    end

    def write_disabled?
      return true if klass == ::Product

      write_disabled
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
      return if data.blank?

      ids = sphinx_document_ids(records)

      index.rt.replace(data)
      index.core.soft_delete(ids)

      prev_rt_delete(index, ids) if index.indexing?
    end
    alias transmit_all transmit

    # Запись объектов в rt index по условию
    #
    # index     - ThinkingSphinx::Index
    # :matching - String
    # where     - Hash
    #
    # Returns nothing
    def retransmit(index, matching: nil, where: {})
      index.distributed.find_in_batches(primary_key: PRIMARY_KEY, matching: matching, where: where) do |rows|
        ids = rows.map { |row| row[PRIMARY_KEY].to_i }
        transmit(index, ids)
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
                     when :boolean then ::StringTools::String.new(value).to_b
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
      sphinx_offset = klass.sphinx_offset
      indexed_models_size = ::ThinkingSphinx.context.indexed_models.size

      records.map do |item|
        if item.respond_to?(:sphinx_document_id)
          item.sphinx_document_id
        else
          item * indexed_models_size + sphinx_offset
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

    def prev_rt_delete(index, ids)
      index.rt.within_partition(index.recent_rt.prev) { |prev_index| prev_index.delete(ids) }
    end
  end
end
