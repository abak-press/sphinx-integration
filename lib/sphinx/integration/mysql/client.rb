module Sphinx
  module Integration
    module Mysql
      class Client
        CORE_INDEX_NAME_POSTFIX = '_core'.freeze

        attr_reader :server_pool

        delegate :log_updates?, :log_core_updates?, to: :'Sphinx::Integration::Helper'

        def initialize(hosts, port, query_log: nil)
          @server_pool = ServerPool.new(hosts, port)
          @query_log = query_log || ::ThinkingSphinx::Configuration.instance.query_log
        end

        def read(sql)
          execute(sql, all: false)
        end

        def write(sql, log_query: false)
          @query_log.add(sql) if log_query

          execute(sql, all: true)
        end

        def replace(index_name, data)
          write(
            ::Riddle::Query::Insert.new(index_name, data.keys, data.values).replace!.to_sql,
            log_query: log_query_to?(index_name)
          )
        end

        def update(index_name, data, matching: nil, **where)
          sql = ::Sphinx::Integration::Extensions::Riddle::Query::Update.
            new(index_name, data, where.merge!(sphinx_deleted: 0), matching).
            to_sql

          write(sql, log_query: log_query_to?(index_name))
        end

        def delete(index_name, document_id)
          write(
            ::Riddle::Query::Delete.new(index_name, document_id).to_sql,
            log_query: log_query_to?(index_name)
          )
        end

        def soft_delete(index_name, document_id)
          update(index_name, {sphinx_deleted: 1}, id: document_id)
        end

        def select(index_name, values, limit: nil, matching: nil, **where)
          limit ||= ThinkingSphinx.max_matches
          where[:sphinx_deleted] = 0
          where_not = where.delete(:not) || where.delete(:where_not) || {}

          query = ::Riddle::Query::Select.new.reset_values.
            values(values).
            from(index_name).
            where(where).
            where_not(where_not).
            limit(limit).
            matching(matching).
            with_options(max_matches: ThinkingSphinx.max_matches)

          read(query.to_sql).to_a
        end

        def find_while_exists(index_name, values, matching: nil, **where)
          1_000_000.times do
            ids = select(index_name, values, matching: matching, **where)
            return if ids.empty?
            yield ids
          end

          raise "Infinite loop detected"
        end

        def find_in_batches(index_name, options = {})
          primary_key = options.fetch(:primary_key, "sphinx_internal_id").to_s.freeze
          batch_size = options.fetch(:batch_size, ThinkingSphinx.max_matches)
          batch_order = "#{primary_key} ASC"
          where = options.fetch(:where, {}).dup
          where[primary_key.to_sym] = -> { "> 0" }
          where[:sphinx_deleted] = 0
          where_not = options.fetch(:where_not, {})

          query = ::Riddle::Query::Select.new.reset_values.
            values(primary_key).
            from(index_name).
            where(where).
            where_not(where_not).
            order_by(batch_order).
            limit(batch_size).
            with_options(max_matches: ThinkingSphinx.max_matches).
            matching(options[:matching])

          records = read(query.to_sql).to_a
          until records.empty?
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

        def execute(sql, all: false)
          result = nil
          ::ThinkingSphinx::Search.log(sql) do
            @server_pool.public_send(all ? :take_all : :take) do |server|
              server.take do |connection|
                result = connection.execute(sql)
              end
            end
          end

          result
        end

        def log_query_to?(index_name)
          if log_core_updates?
            index_name.end_with?(CORE_INDEX_NAME_POSTFIX)
          else
            log_updates?
          end
        end
      end
    end
  end
end
