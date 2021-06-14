require "innertube"
require "socket"

module Sphinx
  module Integration
    module Searchd
      class ConnectionPool
        MAXIMUM_RETRIES = 2

        def initialize(server)
          @server = server

          @pool = Innertube::Pool.new(
            proc { Connection.new(server.host, server.port) },
            proc { |connection| connection.socket.close rescue nil }
          )
        end

        def take
          retries  = 0
          original = nil

          begin
            @pool.take do |connection|
              begin
                yield connection
              rescue Exception => error
                original = error
                raise Innertube::Pool::BadResource
              end
            end
          rescue Innertube::Pool::BadResource
            retries += 1

            if retries >= MAXIMUM_RETRIES
              @server.error_rate << 1
              ::ThinkingSphinx.error(original)
              raise original
            else
              ::ThinkingSphinx.info "Retrying. #{original.message}"
              retry
            end
          end
        end
      end
    end
  end
end
