# coding: utf-8
require 'innertube'

module Sphinx::Integration::Mysql::ConnectionPool
  def self.new_connection
    configuration = ThinkingSphinx::Configuration.instance.configuration
    # If you use localhost, MySQL insists on a socket connection, but Sphinx
    # requires a TCP connection. Using 127.0.0.1 fixes that.
    address = configuration.searchd.address || '127.0.0.1'
    address = '127.0.0.1' if address == 'localhost'

    port = configuration.searchd.mysql41
    port = 9306 if port.is_a?(TrueClass)

    options = {
      :host  => address,
      :port  => port
    }

    Sphinx::Integration::Mysql::Connection.new address, options[:port], options
  end

  def self.pool
    @pool ||= Innertube::Pool.new(
      Proc.new { Sphinx::Integration::Mysql::ConnectionPool.new_connection },
      Proc.new { |connection| connection.close }
    )
  end

  def self.take
    retries  = 0
    original = nil
    begin
      pool.take do |connection|
        begin
          yield connection
        rescue Mysql2::Error => error
          original = ThinkingSphinx::SphinxError.new_from_mysql error
          raise original if original.is_a?(ThinkingSphinx::QueryError)
          raise Innertube::Pool::BadResource
        end
      end
    rescue Innertube::Pool::BadResource
      retries += 1
      retry if retries < 3
      raise original
    end
  end
end