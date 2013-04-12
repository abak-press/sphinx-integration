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
        ThinkingSphinx.take_connection{ |c| c.execute(query) }

        query = "UPDATE #{index.core_name} SET sphinx_deleted = 1 WHERE id = #{record.sphinx_document_id}"
        ThinkingSphinx.take_connection{ |c| c.execute(query) }

        if Redis::Mutex.new(:full_reindex).locked?
          query = Riddle::Query::Insert.new(index.delta_rt_name, data.keys, data.values).replace!.to_sql
          ThinkingSphinx.take_connection{ |c| c.execute(query) }
        end
      end
    end

    # Удаляет запись из сфинкса
    def delete
      rt_indexes do |index|
        query = Riddle::Query::Delete.new(index.rt_name, record.sphinx_document_id).to_sql
        ThinkingSphinx.take_connection{ |c| c.execute(query) }

        query = "UPDATE #{index.core_name} SET sphinx_deleted = 1 WHERE id = #{record.sphinx_document_id}"
        ThinkingSphinx.take_connection{ |c| c.execute(query) }

        if Redis::Mutex.new(:full_reindex).locked?
          query = Riddle::Query::Delete.new(index.delta_rt_name, record.sphinx_document_id).to_sql
          ThinkingSphinx.take_connection{ |c| c.execute(query) }
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

    # Данные, необходимые для записи в индекс сфинкса
    #
    # Returns Hash
    def transmitted_data(index)
      sql = index.single_query_sql.gsub('%{ID}', record.id.to_s)
      row = record.class.connection.execute(sql).first
      row.merge(mva_attributes)
    end

    # MVA data
    #
    # Returns Hash
    def mva_attributes
      attrs = {}
      record.class.methods_for_mva_attributes.each{ |m| attrs.merge! record.send(m) }
      attrs.each do |k, v|
        attrs[k] = "(#{v.join(',')})"
      end
      attrs
    end
  end
end