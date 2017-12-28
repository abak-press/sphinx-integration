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

        def replace(data)
          index_names do |index_name|
            sql = ::Riddle::Query::Insert.
              new(index_name, data.keys, data.values).
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
