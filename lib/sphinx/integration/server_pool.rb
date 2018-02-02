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
            ::ThinkingSphinx.fatal(error_message(e, skip_servers))

            raise
          else
            ::ThinkingSphinx.error(error_message(e, skip_servers))

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
          rescue Exception => e
            skip_servers << server

            if skip_servers.size >= servers.size
              ::ThinkingSphinx.fatal(error_message(e, skip_servers))

              raise
            else
              ::ThinkingSphinx.error(error_message(e, skip_servers))
              ::ThinkingSphinx.info("Error on server #{server}")
            end
          end
        end
      end

      private

      def choose(skip_servers)
        if skip_servers.empty?
          servers = @servers
        else
          servers =  @servers.select { |server| !skip_servers.include?(server) }
        end

        best_servers = servers.select(&:fine?)

        if best_servers.empty?
          @servers.min_by { |server| server.error_rate.value }
        else
          best_servers.sample
        end
      end

      def error_message(error, servers)
        %(Error on servers <#{servers.map(&:to_s).join(", ")}>: "#{error.message}" [#{error.backtrace.join(";")}])
      end
    end
  end
end
