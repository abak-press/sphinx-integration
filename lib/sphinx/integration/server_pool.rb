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
        rescue Exception
          skip_servers << server

          if skip_servers.size >= @servers.size
            ::ThinkingSphinx.fatal("Error on servers: #{skip_servers.map(&:to_s).join(", ")}")
            raise
          else
            server = choose(skip_servers)
            ::ThinkingSphinx.info("Retrying with next server #{server}")
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
          rescue Exception
            skip_servers << server

            if skip_servers.size >= servers.size
              ::ThinkingSphinx.fatal("Error on servers: #{skip_servers.map(&:to_s).join(", ")}")
              raise
            else
              ::ThinkingSphinx.info("Error on server #{server}")
            end
          end
        end
      end

      private

      def choose(skip_servers)
        if skip_servers.any?
          servers =  @servers.select { |server| !skip_servers.include?(server) }
        else
          servers = @servers
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
