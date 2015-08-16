module Sphinx
  module Integration
    class SphinxError < StandardError
      attr_accessor :statement

      def self.new_from_mysql(error)
        case error.message
        when /parse error/
          replacement = ParseError.new(error.message)
        when /syntax error/
          replacement = SyntaxError.new(error.message)
        when /query error/
          replacement = QueryError.new(error.message)
        when /Can't connect to MySQL server/, /Communications link failure/
          replacement = ConnectionError.new(
            "Error connecting to Sphinx via the MySQL protocol. #{error.message}"
          )
        else
          replacement = new(error.message)
        end

        replacement.set_backtrace error.backtrace
        replacement.statement = error.statement if error.respond_to?(:statement)
        replacement
      end
    end

    class ConnectionError < SphinxError
    end

    class QueryError < SphinxError
    end

    class SyntaxError < QueryError
    end

    class ParseError < QueryError
    end

    class QueryExecutionError < StandardError
      attr_accessor :statement
    end

    class Retry < StandardError
    end
  end
end