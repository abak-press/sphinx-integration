module Sphinx
  module Integration
    module Mysql
      class Client
        attr_reader :server_pool

        def initialize(hosts, port, log_enabled: true)
          @server_pool = ServerPool.new(hosts, port)
        end

        def read(sql)
          execute(sql, all: false)
        end

        def write(sql)
          execute(sql, all: true)
        end

        def batch_write(queries)
          @server_pool.take_all do |server|
            server.take do |connection|
              queries.each do |query|
                connection.execute(query)
              end
            end
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
      end
    end
  end
end
