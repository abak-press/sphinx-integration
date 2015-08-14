# coding: utf-8
require 'innertube'

module Sphinx::Integration::Mysql::ConnectionPool
  MAXIMUM_RETRIES = 2

  def self.host_prepared(host)
    host ||= '127.0.0.1'
    # If you use localhost, MySQL insists on a socket connection, but Sphinx
    # requires a TCP connection. Using 127.0.0.1 fixes that.
    host = '127.0.0.1' if host == 'localhost'
    host
  end

  def self.port_prepared(port)
    port.is_a?(TrueClass) ? 9306 : port
  end

  def self.options_for_connection(host, port)
    options = {
      host: host_prepared(host),
      port: port_prepared(port),
      reconnect: true,
      read_timeout: 2,
      connect_timeout: 2
    }
  end

  def self.master_connection
    configuration = ThinkingSphinx::Configuration.instance.configuration
    options = options_for_connection(configuration.searchd.address,
                                     configuration.searchd.mysql41)
    Sphinx::Integration::Mysql::Connection.new(options)
  end

  def self.slave_connection(agent_name)
    agent = ThinkingSphinx::Configuration.instance.agents[agent_name]
    options = options_for_connection(agent[:address], agent[:mysql41])
    Sphinx::Integration::Mysql::Connection.new(options)
  end

  def self.master_pool
    @master_pool ||= Innertube::Pool.new(
      proc { ::Sphinx::Integration::Mysql::ConnectionPool.master_connection },
      proc { |connection| connection.close }
    )
  end

  def self.slaves_pool(agent_name)
    @slaves_pool ||= {}
    @slaves_pool[agent_name] ||= Innertube::Pool.new(
      proc { ::Sphinx::Integration::Mysql::ConnectionPool.slave_connection(agent_name) },
      proc { |connection| connection.close }
    )
  end

  def self.take
    retries  = 0
    original = nil
    begin
      master_pool.take do |connection|
        begin
          yield connection
        rescue ::Sphinx::Integration::QueryExecutionError, Mysql2::Error => error
          original = ::Sphinx::Integration::SphinxError.new_from_mysql(error)
          retries += MAXIMUM_RETRIES if original.is_a?(::Sphinx::Integration::QueryError)
          raise Innertube::Pool::BadResource
        end
      end
    rescue Innertube::Pool::BadResource
      retries += 1

      message = "Retrying. #{original.message}"
      ::ThinkingSphinx.log message

      if retries >= MAXIMUM_RETRIES
        raise original
      else
        retry
      end
    end
  end

  def self.take_slaves
    agents_errors = []
    agents = ThinkingSphinx::Configuration.instance.agents

    agents.each do |agent_name, _|
      retries  = 0
      original = nil

      begin
        slaves_pool(agent_name).take do |connection|
          begin
            yield connection
          rescue ::Sphinx::Integration::QueryExecutionError, Mysql2::Error => error
            original = ::Sphinx::Integration::SphinxError.new_from_mysql(error)
            retries += MAXIMUM_RETRIES if original.is_a?(::Sphinx::Integration::QueryError)
            raise Innertube::Pool::BadResource
          end
        end
      rescue Innertube::Pool::BadResource
        retries += 1

        message = "Retrying. #{original.message}"
        ::ThinkingSphinx.log message

        if retries >= MAXIMUM_RETRIES
          agents_errors << original
        else
          retry
        end
      end
    end

    return unless agents_errors.size >= agents.size
    raise agents_errors[0]
  end
end
