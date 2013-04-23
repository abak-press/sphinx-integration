# coding: utf-8
require 'redis-mutex'

module Sphinx::Integration
  class Transmitter
    attr_reader :record

    def initialize(record)
      @record = record
    end

    # Обновляет запись в сфинксе
    def replace
      rt_indexes do |index|
        data = transmitted_data(index)

        query = Riddle::Query::Insert.new(index.rt_name, data.keys, data.values).replace!.to_sql
        execute(query)

        query = "UPDATE #{index.core_name} SET sphinx_deleted = 1 WHERE id = #{record.sphinx_document_id}"
        execute(query)

        if Redis::Mutex.new(:full_reindex).locked?
          query = Riddle::Query::Insert.new(index.delta_rt_name, data.keys, data.values).replace!.to_sql
          execute(query)
        end
      end
    end
    alias_method :create, :replace
    alias_method :update, :replace

    # Удаляет запись из сфинкса
    def delete
      rt_indexes do |index|
        query = Riddle::Query::Delete.new(index.rt_name, record.sphinx_document_id).to_sql
        execute(query)

        query = "UPDATE #{index.core_name} SET sphinx_deleted = 1 WHERE id = #{record.sphinx_document_id}"
        execute(query)

        if Redis::Mutex.new(:full_reindex).locked?
          query = Riddle::Query::Delete.new(index.delta_rt_name, record.sphinx_document_id).to_sql
          execute(query)
        end
      end
    end

    private

    # Итератор по всем rt индексам
    def rt_indexes
      record.class.sphinx_indexes.select(&:rt?).each do |index|
        yield index
      end
    end

    # Посылает запрос в Sphinx
    #
    # query - String
    def execute(query)
      log(query)
      ThinkingSphinx.take_connection{ |c| c.execute(query) }
    end

    # Данные, необходимые для записи в индекс сфинкса
    #
    # index - ThinkingSphinx::Index
    #
    # Returns Hash
    def transmitted_data(index)
      sql = index.single_query_sql.gsub('%{ID}', record.id.to_s)
      row = record.class.connection.execute(sql).first
      row.merge!(mva_attributes(index))

      row.each do |key, value|
        row[key] = case index.attributes_types_map[key]
          when :integer then value.to_i
          when :float then value.to_f
          when :multi then value.is_a?(String) ? value.split(',') : value
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
    def mva_attributes(index)
      attrs = {}

      index.mva_sources.each do |name, mva_proc|
        attrs[name] = mva_proc.call(record)
      end if index.mva_sources

      attrs
    end

    # Залогировать
    #
    # message - String
    def log(message)
      ::ActiveSupport::Notifications.instrument('message.thinking_sphinx', :message => message)
    end
  end
end