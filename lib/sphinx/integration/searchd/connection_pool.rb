require "innertube"
require "socket"

module Sphinx
  module Integration
    module Searchd
      class ConnectionPool
        MAXIMUM_RETRIES = 3

        @pool = {}
        @lock = Mutex.new

        class << self
          # Open or reuse socket connection
          #
          # options - Hash
          #           :server  - String (required)
          #           :port    - Integer (required)
          def take(options)
            retries  = 0
            original = nil
            begin
              pool(options).take do |socket|
                begin
                  yield socket
                rescue Exception => error
                  original = error
                  raise Innertube::Pool::BadResource
                end
              end
            rescue Innertube::Pool::BadResource
              retries += 1

              if retries >= MAXIMUM_RETRIES
                ::ThinkingSphinx.fatal(original)
                raise ::Riddle::ConnectionError, "Connection to #{options.inspect} failed. #{original.message}"
              else
                ::ThinkingSphinx.error "Retrying. #{original.message}"
                retry
              end
            end
          end

          def socket(options)
            socket = TCPSocket.new(options.fetch(:server), options.fetch(:port))

            version = socket.recv(4).unpack('N*').first
            if version < 1
              socket.close
              raise ::Riddle::VersionError,
                    "Can only connect to searchd version 1.0 or better, not version #{version}"
            end
            socket.send [1].pack('N'), 0

            core_header = [::Riddle::Client::Commands[:persist], 0, 4].pack("nnN")
            socket.send core_header + [1].pack('N'), 0

            socket
          end

          private

          def pool(options)
            @lock.synchronize do
              @pool[options.fetch(:server)] ||= Innertube::Pool.new(
                proc { ::Sphinx::Integration::Searchd::ConnectionPool.socket(options) },
                proc { |socket| socket.close rescue nil }
              )
            end
          end
        end
      end
    end
  end
end
