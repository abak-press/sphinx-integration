# coding: utf-8
require "innertube"

module Sphinx
  module Integration
    module Mysql
      class ConnectionPool
        MAXIMUM_RETRIES = 2

        def initialize(server)
          @server = server

          @pool = Innertube::Pool.new(
            proc { Connection.new(server.host, server.port) },
            proc { |connection| connection.close }
          )
        end

        def take
          retries  = 0
          original = nil

          begin
            @pool.take do |connection|
              begin
                yield connection
              # Если ошибка сфинкса нам не ведома - удаляем ресурс
              rescue Mysql2::Error => error
                original = error
                raise Innertube::Pool::BadResource
              rescue ::Sphinx::Integration::QueryExecutionError => error
                original = ::Sphinx::Integration::SphinxError.new_from_mysql(error)

                case original
                # Если сфинкс недосутпен - удаляем ресурс
                when ::Sphinx::Integration::ConnectionError
                  raise Innertube::Pool::BadResource
                # Если ошибка в запросе, переповторять запрос не будем
                when ::Sphinx::Integration::QueryError
                  retries += MAXIMUM_RETRIES
                end

                raise ::Sphinx::Integration::Retry
              end
            end
          rescue Innertube::Pool::BadResource, ::Sphinx::Integration::Retry
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
