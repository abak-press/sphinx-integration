# frozen_string_literal: true
module Sphinx
  module Integration
    module Extensions
      module Riddle
        module Client
          MAXIMUM_RETRIES = 2
          HEADER_LENGTH = 8
          READ_TIMEOUT = 3

          extend ActiveSupport::Concern

          included do
            alias_method_chain :initialize, :pooling
            alias_method_chain :connect, :pooling
            alias_method_chain :request, :pooling
          end

          module ClassMethods
            def server_pool
              @server_pool
            end

            def init_server_pool(servers, port)
              @server_pool = ::Sphinx::Integration::ServerPool.new(servers, port, mysql: false)
            end
          end

          def initialize_with_pooling(*args)
            initialize_without_pooling(*args)

            self.class.init_server_pool(@servers, @port) unless self.class.server_pool
          end

          def connect_with_pooling
            self.class.server_pool.take do |server|
              server.take do |connection|
                yield connection.socket
              end
            end
          end

          def request_with_pooling(command, messages)
            response = ''.dup
            status   = -1
            version  = 0
            length   = 0
            message  = ::Riddle.encode(Array(messages).join(''), 'ASCII-8BIT')

            connect do |socket|
              case command
              when :search
                if ::Riddle::Client::Versions[command] >= 0x118
                  socket.send request_header(command, message.length) +
                    [0, messages.length].pack('NN') + message, 0
                else
                  socket.send request_header(command, message.length) +
                    [messages.length].pack('N') + message, 0
                end
              when :status
                socket.send request_header(command, message.length), 0
              else
                socket.send request_header(command, message.length) + message, 0
              end

              header = ''.dup
              read_with_timeout!(socket, HEADER_LENGTH, header)
              status, version, length = header.unpack('n2N')

              # Если вернулся ответ Retry, то нужно попробовать
              # отправить запрос на другую ноду, если имеется таковая
              # дальнейшее чтение из сокета ненужно, закроем его выше
              if ::Riddle::Client::Statuses[:retry] == status
                raise ::Riddle::ResponseError, 'Searchd responded with retry error'
              end

              read_with_timeout!(socket, length, response)

              if response.empty? || response.bytesize != length
                raise ::Riddle::ResponseError, "No response from searchd (status: #{status}, version: #{version})"
              end
            end

            case status
            when ::Riddle::Client::Statuses[:ok]
              if version < ::Riddle::Client::Versions[command]
                puts format("searchd command v.%d.%d older than client (v.%d.%d)",
                  version >> 8, version & 0xff,
                  ::Riddle::Client::Versions[command] >> 8, ::Riddle::Client::Versions[command] & 0xff)
              end
              response
            when ::Riddle::Client::Statuses[:warning]
              length = response[0, 4].unpack('N*').first
              puts response[4, length]
              response[4 + length, response.length - 4 - length]
            when ::Riddle::Client::Statuses[:error]
              message = response[4, response.length - 4]
              klass = message[/out of bounds/] ? ::Riddle::OutOfBoundsError : ::Riddle::ResponseError
              raise klass, "searchd error (status: #{status}): #{message}"
            else
              raise ::Riddle::ResponseError, "Unknown searchd error (status: #{status})"
            end
          end

          # Private: читает из sock maxlength байт в outbuf используя read(2) syscall и select(2)
          # после выставления флага на сокет O_NONBLOCK, с таймаутом timeout секунд
          def read_with_timeout!(sock, maxlength, outbuf, timeout: READ_TIMEOUT)
            raise ::Riddle::ResponseError, 'Timeout reading from socket' if timeout == 0

            sock_ready = IO.select(_read_fds = [sock], _write_fds = [], _exception_fds = [], 1)
            # Timeout
            return read_with_timeout!(sock, maxlength, outbuf, timeout: timeout-1) if sock_ready.nil?

            begin
              outbuf << sock.read_nonblock(maxlength)
            rescue IO::WaitReadable
            end

            # Read it all?
            return outbuf if maxlength == outbuf.bytesize

            read_with_timeout!(sock, maxlength, outbuf, timeout: timeout-1)
          end
        end
      end
    end
  end
end
