module Sphinx
  module Integration
    class ServerPool
      def initialize(hosts, port, options = {})
        @servers = Array.wrap(hosts).map { |host| Server.new(host, port, options) }
      end

      def find_server(host)
        @servers.find { |server| server.host == host }
      end

      def take
        skip_servers = Set.new
        server = choose(skip_servers)

        begin
          yield server
        rescue Exception => e
          skip_servers << server

          if skip_servers.size >= @servers.size
            ::ThinkingSphinx.fatal("Error on servers: #{skip_servers.map(&:to_s).join(', ')}")
            ::ThinkingSphinx.debug("#{e.message}\n#{e.backtrace.join("\n")}")
            raise
          else
            server_was = server
            server = choose(skip_servers)
            ::ThinkingSphinx.error("#{server_was}: #{e.message}")
            ::ThinkingSphinx.info("Retrying with next server #{server}, was #{server_was}")
            ::ThinkingSphinx.debug(e.backtrace.join("\n"))
            retry
          end
        end
      end

      def take_all
        skip_servers = Set.new
        servers = @servers.select { |server| server.server_status.available? }

        servers.each do |server|
          begin
            yield server
          rescue Exception => e
            skip_servers << server

            if skip_servers.size >= servers.size
              ::ThinkingSphinx.fatal("Error on servers: #{skip_servers.map(&:to_s).join(', ')}")
              ::ThinkingSphinx.debug("#{e.message}\n#{e.backtrace.join("\n")}")
              raise
            else
              ::ThinkingSphinx.info("Error on server #{server}")
              ::ThinkingSphinx.debug("#{e.message}\n#{e.backtrace.join("\n")}")
            end
          end
        end
      end

      private

      def choose(skip_servers)
        servers = if skip_servers.empty?
                    @servers
                  else
                    @servers.reject { |server| skip_servers.include?(server) }
                  end

        best_servers = servers.select(&:fine?)

        if best_servers.empty?
          @servers.min_by { |server| server.error_rate.value }
        else
          best_servers.sample
        end
      end
    end
  end
end
