# coding: utf-8
require 'redis-mutex'

module Sphinx::Integration
  class Transmitter
    attr_reader :klass

    def initialize(klass)
      @klass = klass
    end

    # Обновляет запись в сфинксе
    #
    # record - ActiveRecord::Base
    #
    # Returns nothing
    def replace(record)
      rt_indexes do |index|
        if (data = transmitted_data(index, record))
          sphinx_replace(index.rt_name, data)
          sphinx_soft_delete(index.core_name_w, record.sphinx_document_id) if record.exists_in_sphinx?(index.core_name)
          sphinx_replace(index.delta_rt_name, data) if write_delta?
        end
      end
    end

    # Удаляет запись из сфинкса
    #
    # record - ActiveRecord::Base
    #
    # Returns nothing
    def delete(record)
      rt_indexes do |index|
        sphinx_delete(index.rt_name_w, record.sphinx_document_id)
        sphinx_soft_delete(index.core_name_w, record.sphinx_document_id) if record.exists_in_sphinx?(index.core_name)
        sphinx_delete(index.delta_rt_name_w, record.sphinx_document_id) if write_delta?
      end
    end

    # Обновление отдельных атрибутов записи
    #
    # record - ActiveRecord::Base
    # data   - Hash (:field => :value)
    #
    # Returns nothing
    def update(record, data)
      update_fields(data, {:id => record.sphinx_document_id})
    end

    # Обновление отдельных атрибутов индекса по условию
    #
    # fields - Hash (:field => :value)
    # where  - Hash
    #
    # Returns nothing
    def update_fields(fields, where)
      rt_indexes do |index|
        if write_delta?
          ids = sphinx_select('sphinx_internal_id', index.name, where).map{ |row| row['sphinx_internal_id'] }
          ids.in_groups_of(500, false) do |group_ids|
            klass.where(:id => group_ids).each { |record| replace(record) }
          end if ids.any?
        else
          sphinx_update(index.name_w, fields, where)
        end
      end
    end

    protected

    # Данные, необходимые для записи в индекс сфинкса
    #
    # index  - ThinkingSphinx::Index
    # record - ActiveRecord::Base
    #
    # Returns Hash
    def transmitted_data(index, record)
      sql = index.single_query_sql.gsub('%{ID}', record.id.to_s)
      if index.local_options[:with_sql] && index.local_options[:with_sql][:update]
        sql = index.local_options[:with_sql][:update].call(sql)
      end
      row = record.class.connection.execute(sql).first
      return unless row
      row.merge!(mva_attributes(index, record))

      row.each do |key, value|
        row[key] = case index.attributes_types_map[key]
          when :integer then value.to_i
          when :float then value.to_f
          when :multi then type_cast_to_multi(value)
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

    private

    # Итератор по всем rt индексам
    #
    # Yields ThinkingSphinx::Index
    #
    # Returns nothing
    def rt_indexes
      klass.sphinx_indexes.select(&:rt?).each do |index|
        yield index
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

    # Залогировать
    #
    # message - String
    def log(message)
      ::ActiveSupport::Notifications.instrument('message.thinking_sphinx', :message => message)
    end

    def config
      ThinkingSphinx::Configuration.instance
    end

    def replication?
      config.replication?
    end

    def write_delta?
      Redis::Mutex.new(:full_reindex).locked?
    end

    def sphinx_replace(index_name, data)
      query = Riddle::Query::Insert.new(index_name, data.keys, data.values).replace!.to_sql
      ThinkingSphinx.execute(query, :on_slaves => replication?)
    end

    def sphinx_update(index_name, data, where)
      query = ::Sphinx::Integration::Extensions::Riddle::Query::Update.new(index_name, data, where).to_sql
      ThinkingSphinx.execute(query)
    end

    def sphinx_delete(index_name, document_id)
      query = Riddle::Query::Delete.new(index_name, document_id).to_sql
      ThinkingSphinx.execute(query)
    end

    def sphinx_soft_delete(index_name, document_id)
      sphinx_update(index_name, {:sphinx_deleted => 1}, {:id => document_id})
    end

    def sphinx_select(values, index_name, where)
      query = Riddle::Query::Select.
        new.
        reset_values.
        values(values).
        from(index_name).
        where(where).
        to_sql
      ThinkingSphinx.execute(query).to_a
    end
  end
end