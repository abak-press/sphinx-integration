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
      self.class.rt_indexes(record.class) do |index|
        if (data = transmitted_data(index))
          query = Riddle::Query::Insert.new(index.rt_name, data.keys, data.values).replace!.to_sql
          self.class.execute(query)

          query = "UPDATE #{index.core_name} SET sphinx_deleted = 1 WHERE id = #{record.sphinx_document_id}"
          self.class.execute(query)

          if Redis::Mutex.new(:full_reindex).locked?
            query = Riddle::Query::Insert.new(index.delta_rt_name, data.keys, data.values).replace!.to_sql
            self.class.execute(query)
          end
        end
      end
    end
    alias_method :create, :replace
    alias_method :update, :replace

    # Удаляет запись из сфинкса
    def delete
      self.class.rt_indexes(record.class) do |index|
        query = Riddle::Query::Delete.new(index.rt_name, record.sphinx_document_id).to_sql
        self.class.execute(query)

        query = "UPDATE #{index.core_name} SET sphinx_deleted = 1 WHERE id = #{record.sphinx_document_id}"
        self.class.execute(query)

        if Redis::Mutex.new(:full_reindex).locked?
          query = Riddle::Query::Delete.new(index.delta_rt_name, record.sphinx_document_id).to_sql
          self.class.execute(query)
        end
      end
    end

    # Обновление отдельных атрибутов записи
    #
    # fields - Hash (:field => :value)
    def update_fields(fields)
      self.class.update_all_fields(record.class, fields, "id = #{record.sphinx_document_id}")
    end

    # Обновление отдельных атрибутов индекса по условию
    #
    # klass - Class
    # fields - Hash (:field => :value)
    # where - String (company_id = 123)
    def self.update_all_fields(klass, fields, where)
      rt_indexes(klass) do |index|
        query = ::Sphinx::Integration::Extensions::Riddle::Query::Update.new(index.rt_name, fields, where).to_sql
        execute(query)

        query = "UPDATE #{index.core_name} SET sphinx_deleted = 1 WHERE #{where}"
        execute(query)

        if Redis::Mutex.new(:full_reindex).locked?
          query = ::Sphinx::Integration::Extensions::Riddle::Query::Update.new(index.delta_rt_name, fields, where).to_sql
          execute(query)
        end
      end
    end

    private

    # Итератор по всем rt индексам
    #
    # klass - Class
    def self.rt_indexes(klass)
      klass.sphinx_indexes.select(&:rt?).each do |index|
        yield index
      end
    end

    # Посылает запрос в Sphinx
    #
    # query - String
    def self.execute(query)
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
      if index.local_options[:with_sql] && index.local_options[:with_sql][:update]
        sql = index.local_options[:with_sql][:update].call(sql)
      end
      row = record.class.connection.execute(sql).first
      return unless row
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
    def self.log(message)
      ::ActiveSupport::Notifications.instrument('message.thinking_sphinx', :message => message)
    end
  end
end