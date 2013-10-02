# coding: utf-8
require 'innertube'

module Sphinx::Integration::Mysql::ConnectionPool

  def self.address_prepared(address)
    address = address || '127.0.0.1'
    # If you use localhost, MySQL insists on a socket connection, but Sphinx
    # requires a TCP connection. Using 127.0.0.1 fixes that.
    address = '127.0.0.1' if address == 'localhost'
    address
  end

  def self.port_prepared(port)
    port.is_a?(TrueClass) ? 9306 : port
  end

  def self.master_connection
    configuration = ThinkingSphinx::Configuration.instance.configuration

    options = {
      :host  => address_prepared(configuration.searchd.address),
      :port  => port_prepared(configuration.searchd.mysql41),
      :reconnect => true
    }

    Sphinx::Integration::Mysql::Connection.new options[:host], options[:port], options
  end

  def self.slave_connection(agent_name)
    ts_config = ThinkingSphinx::Configuration.instance
    agent = ts_config.agents[agent_name]

    options = {
      :host => address_prepared(agent[:address]),
      :port  => port_prepared(agent[:mysql41]),
      :reconnect => true
    }

    Sphinx::Integration::Mysql::Connection.new options[:host], options[:port], options
  end

  def self.master_pool
    @master_pool ||= Innertube::Pool.new(
      Proc.new { Sphinx::Integration::Mysql::ConnectionPool.master_connection },
      Proc.new { |connection| connection.close }
    )
  end

  def self.agents_pool(agent_name)
    return @agents_pool[agent_name] if @agents_pool.key?(agent_name)

    @take_slaves_mutex.synchronize do
      return @agents_pool[agent_name] if @agents_pool.key?(agent_name)

      @agents_pool[agent_name] ||= Innertube::Pool.new(
        Proc.new { Sphinx::Integration::Mysql::ConnectionPool.slave_connection(agent_name) },
        Proc.new { |connection| connection.close }
      )
    end
  end

  def self.take
    retries  = 0
    original = nil
    begin
      master_pool.take do |connection|
        begin
          yield connection
        rescue Mysql2::Error => error
          original = error
          if error.message =~ /(parse|syntax|query) error/
            raise error
          else
            raise Innertube::Pool::BadResource
          end
        end
      end
    rescue Innertube::Pool::BadResource
      retries += 1
      retry if retries < 2
      raise original
    end
  end

  def self.take_slaves(silent = true)
    @take_slaves_mutex ||= Mutex.new
    @agents_pool ||= {}

    threads = []

    ThinkingSphinx::Configuration.instance.agents.each do |agent_name, _|
      threads << Thread.new do

        retries  = 0
        original = nil

        begin
          agents_pool(agent_name).take do |connection|
            begin
              yield connection
            rescue Mysql2::Error => error
              original = error
              if error.message =~ /(parse|syntax|query) error/
                raise error
              else
                raise Innertube::Pool::BadResource
              end
            end
          end
        rescue Mysql2::Error => e
          if silent
            Rails.logger.warn e.message
          else
            raise e
          end
        rescue Innertube::Pool::BadResource
          retries += 1
          retry if retries < 2
          raise original
        end

      end
    end

    threads.each { |t| t.join }
  end
end