# coding: utf-8
require 'innertube'

module Sphinx::Integration::Mysql::ConnectionPool
  MAXIMUM_RETRIES = 2

  @slaves_pool = {}
  @master_lock = Mutex.new
  @slaves_lock = Mutex.new

  class << self
    def take(pool = nil)
      retries  = 0
      original = nil
      begin
        (pool || master_pool).take do |connection|
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
          ::ThinkingSphinx.error(original)
          raise original
        else
          ::ThinkingSphinx.info "Retrying. #{original.message}"
          retry
        end
      end
    end

    def take_slaves(&block)
      @agents ||= ThinkingSphinx::Configuration.instance.agents
      errors = []

      @agents.each do |agent_name, _|
        begin
          take(slaves_pool(agent_name), &block)
        rescue ::Innertube::Pool::BadResource,
               ::Mysql2::Error,
               ::Sphinx::Integration::QueryExecutionError,
               ::Sphinx::Integration::SphinxError => error
          errors << error
        end
      end

      # Райзим ошибку, только если она получаена от обоих реплик
      return if errors.size < @agents.size
      raise errors[0]
    end

    def master_connection
      configuration = ThinkingSphinx::Configuration.instance.configuration
      options = options_for_connection(configuration.searchd.address,
                                       configuration.searchd.mysql41)
      Sphinx::Integration::Mysql::Connection.new(options)
    end

    def slave_connection(agent_name)
      agent = ThinkingSphinx::Configuration.instance.agents[agent_name]
      options = options_for_connection(agent[:address], agent[:mysql41])
      Sphinx::Integration::Mysql::Connection.new(options)
    end

    private

    def host_prepared(host)
      host ||= '127.0.0.1'
      # If you use localhost, MySQL insists on a socket connection, but Sphinx
      # requires a TCP connection. Using 127.0.0.1 fixes that.
      host = '127.0.0.1' if host == 'localhost'
      host
    end

    def port_prepared(port)
      port.is_a?(TrueClass) ? 9306 : port
    end

    def options_for_connection(host, port)
      {
        host: host_prepared(host),
        port: port_prepared(port),
        reconnect: true,
        read_timeout: 2,
        connect_timeout: 2
      }
    end

    def master_pool
      @master_lock.synchronize do
        @master_pool ||= Innertube::Pool.new(
          proc { ::Sphinx::Integration::Mysql::ConnectionPool.master_connection },
          proc { |connection| connection.close }
        )
      end
    end

    def slaves_pool(agent_name)
      @slaves_lock.synchronize do
        @slaves_pool[agent_name] ||= Innertube::Pool.new(
          proc { ::Sphinx::Integration::Mysql::ConnectionPool.slave_connection(agent_name) },
          proc { |connection| connection.close }
        )
      end
    end
  end
end
