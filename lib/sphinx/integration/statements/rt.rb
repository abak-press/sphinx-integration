module Sphinx
  module Integration
    module Statements
      class Rt < Distributed
        def within_partition(value)
          @partition = value
          yield self
        ensure
          @partition = nil
        end

        # Public: sends REPLACE query
        #
        # data - Array of Hashes
        #
        # Returns nothing
        def replace(data)
          query_data = Array.wrap(data)

          query_keys = query_data.first.keys

          raise ArgumentError.new('invalid schema of data') unless query_data.all? { |item| item.keys == query_keys }
          query_values = query_data.map!(&:values)

          index_names do |index_name|
            sql = ::Riddle::Query::Insert.
              new(index_name, query_keys, query_values).
              replace!.
              to_sql

            write(sql)

            yield(index_name, sql) if block_given?
          end
        end

        def delete(document_id)
          index_names do |index_name|
            sql = ::Riddle::Query::Delete.
              new(index_name, document_id).
              to_sql

            write(sql)

            yield(index_name, sql) if block_given?
          end
        end

        def truncate
          index_names do |index_name|
            write("TRUNCATE RTINDEX #{index_name}")
          end
        end

        private

        def index_names
          if @partition
            yield @index.rt_name(@partition)
          elsif @index.indexing?
            yield @index.rt_name(0)
            yield @index.rt_name(1)
          else
            yield first_index_name
          end
        end

        def first_index_name
          @index.rt_name
        end
      end
    end
  end
end
