module Sphinx
  module Integration
    module Mysql
      class Client
        attr_reader :server_pool

        def initialize(hosts, port)
          @server_pool = ServerPool.new(hosts, port)
        end

        def read(sql)
          execute(sql, all: false)
        end

        def write(sql)
          execute(sql, all: true)
        end

        def replace(index_name, data)
          write ::Riddle::Query::Insert.new(index_name, data.keys, data.values).replace!.to_sql
        end

        def update(index_name, data, where)
          write ::Sphinx::Integration::Extensions::Riddle::Query::Update.new(index_name, data, where).to_sql
        end

        def delete(index_name, document_id)
          write ::Riddle::Query::Delete.new(index_name, document_id).to_sql
        end

        def soft_delete(index_name, document_id)
          update(index_name, {sphinx_deleted: 1}, id: document_id)
        end

        def select(values, index_name, where, limit = nil)
          sql = ::Riddle::Query::Select.
            new.
            reset_values.
            values(values).
            from(index_name).
            where(where).
            limit(limit).
            to_sql

          read(sql).to_a
        end

        def find_in_batches(index_name, options = {})
          primary_key = options.fetch(:primary_key, "sphinx_internal_id").to_s.freeze
          batch_size = options.fetch(:batch_size, ThinkingSphinx.max_matches)
          batch_order = "#{primary_key} ASC"
          where = options.fetch(:where, {})
          where[primary_key.to_sym] = -> { "> 0" }
          where_not = options.fetch(:where_not, {})

          query = ::Riddle::Query::Select.new.reset_values.
            values(primary_key).
            from(index_name).
            where(where).
            where_not(where_not).
            order_by(batch_order).
            limit(batch_size).
            matching(options[:matching])

          records = read(query.to_sql).to_a
          while records.any?
            primary_key_offset = records.last[primary_key].to_i

            records.map! { |record| record[primary_key].to_i }
            yield records

            break if records.size < batch_size

            where[primary_key.to_sym] = -> { "> #{primary_key_offset}" }
            query.where(where)
            records = read(query.to_sql).to_a
          end
        end

        private

        def execute(sql, options = {})
          result = nil
          ::ThinkingSphinx::Search.log(sql) do
            @server_pool.send(options[:all] ? :take_all : :take) do |server|
              server.take do |connection|
                result = connection.execute(sql)
              end
            end
          end

          result
        end
      end
    end
  end
end
