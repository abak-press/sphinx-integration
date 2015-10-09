module Sphinx
  module Integration
    module Searchd
      class Connection
        def initialize(host, port)
          @host = host
          @port = port
        end

        def socket
          return @socket if @socket

          @socket = TCPSocket.new(@host, @port)
          check_version
          @socket.send [1].pack('N'), 0
          core_header = [::Riddle::Client::Commands[:persist], 0, 4].pack("nnN")
          @socket.send core_header + [1].pack('N'), 0

          @socket
        end

        private

        def check_version
          version = @socket.recv(4).unpack('N*').first
          return unless version < 1
          @socket.close
          raise ::Riddle::VersionError,
                "Can only connect to searchd version 1.0 or better, not version #{version}"
        end
      end
    end
  end
end
