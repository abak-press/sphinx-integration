require "mysql2"

module Sphinx
  module Integration
    module Mysql
      class Connection
        QUERIES_DELIMETER = ';'.freeze

        def initialize(host, port)
          config = ::ThinkingSphinx::Configuration.instance

          @client_options = {
            host: host,
            port: port,
            flags: Mysql2::Client::MULTI_STATEMENTS,
            reconnect: true,
            read_timeout: config.mysql_read_timeout,
            connect_timeout: config.mysql_connect_timeout
          }
        end

        def close
          client.close
        rescue
          # silence close
        end

        def execute(statement)
          query(statement)
        end

        def query_all(*statements)
          query(*statements)
        end

        private

        def client
          @client ||= ::Mysql2::Client.new(@client_options)
        rescue Mysql2::Error => error
          raise ::Sphinx::Integration::QueryExecutionError.new(error)
        end

        def close_and_clear
          close
          @client = nil
        end

        def query(*statements)
          results_for(*statements)
        rescue => error
          human_statements = statements.join('; ')
          message = "#{error.message} - #{human_statements}"
          wrapper = ::Sphinx::Integration::QueryExecutionError.new message
          wrapper.statement = human_statements
          raise wrapper
        end

        def results_for(*statements)
          if statements.size > 1
            results = [client.query(statements.join(QUERIES_DELIMETER))]
            results << client.store_result while client.next_result
            results
          else
            client.query(statements[0])
          end
        end
      end
    end
  end
end
