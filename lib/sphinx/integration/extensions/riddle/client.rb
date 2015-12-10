# coding: utf-8
module Sphinx
  module Integration
    module Extensions
      module Riddle
        module Client
          MAXIMUM_RETRIES = 2

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

          # Пришлось скопировать почти полносью
          # Ну и метод красотой и не блещит, поэтому как то так
          # Вся суть заклучается в тои, что в connect обернуть весь метод
          def request_with_pooling(command, messages)
            response = ""
            status   = -1
            version  = 0
            length   = 0
            message  = ::Riddle.encode(Array(messages).join(""), 'ASCII-8BIT')

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

              header = socket.recv(8)
              status, version, length = header.unpack('n2N')

              while response.length < (length || 0)
                part = socket.recv(length - response.length)

                # will return 0 bytes if remote side closed TCP connection, e.g, searchd segfaulted.
                break if part.length == 0 && socket.is_a?(TCPSocket)

                response << part if part
              end

              if response.empty? || response.length != length
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
            when ::Riddle::Client::Statuses[:error], ::Riddle::Client::Statuses[:retry]
              message = response[4, response.length - 4]
              klass = message[/out of bounds/] ? ::Riddle::OutOfBoundsError : ::Riddle::ResponseError
              raise klass, "searchd error (status: #{status}): #{message}"
            else
              raise ::Riddle::ResponseError, "Unknown searchd error (status: #{status})"
            end
          end
        end
      end
    end
  end
end
