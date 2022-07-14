module Sphinx
  module Integration
    module Statements
      class Rt < Distributed
        def initialize(index)
          super

          @process_mutex = ::Sphinx.mutex_class.new(RT_INDEXES_PROCESS_MUTEX_KEY, expire: RT_INDEXES_PROCESS_MUTEX_TTL)
        end

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

          sql = ::Riddle::Query::Insert.
            new(index_name, query_keys, query_values).
            replace!.
            to_sql

          write(sql)

          yield(sql) if block_given?
        end

        def delete(document_ids)
          sql = ::Riddle::Query::Delete.
            new(index_name, Array.wrap(document_ids)).
            to_sql

          write(sql)

          yield(index_name, sql) if block_given?
        end

        # Public: очищает real-time индекс
        # Это привилегированная процедура, и запрос отправляется через vip-порт, что позволяет выполнить запрос
        # в сфинксе в отдельном воркере вне общего пула потоков. Это даст гарантию того, что индексация завершится
        # корректно.
        # https://manual.manticoresearch.com/Connecting_to_the_server/MySQL_protocol#VIP-connection
        #
        # Returns nothing
        def truncate(host = nil)
          delay = 60.seconds
          retries_count = 15

          begin
            @process_mutex.lock!
            write_to_vip_port("TRUNCATE RTINDEX #{index_name}", host)
          rescue ::Sphinx.mutex_lock_error_class
            if (retries_count -= 1) > 0
              sleep delay
              retry
            end

            raise
          end
        ensure
          @process_mutex.unlock(_force = true)
        end

        private

        def index_name
          if @partition
            @index.rt_name(@partition)
          else
            @index.rt_name
          end
        end
      end
    end
  end
end
