# coding: utf-8
module Sphinx::Integration
  class Transmitter
    attr_reader :record

    def initialize(record)
      @record = record
    end

    def destroy
      record.class.sphinx_indexes.each do |index|
        delete_in_rt(index) if index.rt?
      end
    end

    def create
      record.class.sphinx_indexes.each do |index|
        replace_in_rt(index) if index.rt?
      end
    end

    def update
      record.class.sphinx_indexes.each do |index|
        replace_in_rt(index) if index.rt?
      end
    end

    protected

    def mva_sphinx_attributes
      attrs = {}
      record.class.methods_for_mva_attributes.each{ |m| attrs.merge! record.send(m) }
      attrs.each do |k, v|
        attrs[k] = "(#{v.join(',')})"
      end
      attrs
    end

    def transmitted_data(index)
      sql = index.single_query_sql.gsub('%{ID}', record.id.to_s)
      row = record.class.connection.execute(sql).first
      row.merge(mva_sphinx_attributes)
    end

    def delete_in_rt(index)
      sphinxql = Riddle::Query::Delete.new(index.rt_name, record.sphinx_document_id)
      ThinkingSphinx.take_connection{ |c| c.execute(sphinxql.to_sql) }

      if Redis::Mutex.new(:full_reindex).locked?
        sphinxql = Riddle::Query::Delete.new(index.delta_rt_name, record.sphinx_document_id)
        ThinkingSphinx.take_connection{ |c| c.execute(sphinxql.to_sql) }
      end
    end

    def replace_in_rt(index)
      row = transmitted_data(index)

      sphinxql = Riddle::Query::Insert.new(index.rt_name, row.keys, row.values)
      ThinkingSphinx.take_connection{ |c| c.execute(sphinxql.replace!.to_sql) }

      if Redis::Mutex.new(:full_reindex).locked?
        sphinxql = Riddle::Query::Insert.new(index.delta_rt_name, row.keys, row.values)
        ThinkingSphinx.take_connection{ |c| c.execute(sphinxql.replace!.to_sql) }
      end
    end

  end
end