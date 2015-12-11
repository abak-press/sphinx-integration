module Sphinx
  module Integration
    class Server
      attr_reader :host, :port, :error_rate, :server_status, :pool

      def initialize(host, port, options = {})
        @host = host
        @port = port
        @error_rate = ::Sphinx::Integration::Decaying.new
        @server_status = ::Sphinx::Integration::ServerStatus.new(host)

        @pool = if options.fetch(:mysql, true)
                  Mysql::ConnectionPool.new(self)
                else
                  Searchd::ConnectionPool.new(self)
                end
      end

      def take
        pool.take { |connection| yield connection }
      end

      def fine?
        error_rate.satisfy? && server_status.available?
      end

      def to_s
        "<Server #{@host}:#{@port}>"
      end
    end
  end
end
