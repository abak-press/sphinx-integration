require "request_store"

module Sphinx
  module Integration
    class ServerStatus
      AVAILABLE_FIELD = "available".freeze

      def initialize(host)
        @host = host
      end

      def available?
        ::RequestStore.fetch(store_key) do
          !(::Redis.current.hget(redis_key, AVAILABLE_FIELD) || 1).to_i.zero?
        end
      end

      def available=(value)
        ::RequestStore.delete(store_key)
        ::Redis.current.hset(redis_key, AVAILABLE_FIELD, value ? 1 : 0)
      end

      private

      def store_key
        @store_key ||= "sphinx_server_availability/#{@host}"
      end

      def redis_key
        @redis_key ||= "sphinx/integration/server_status:#{@host}"
      end
    end
  end
end
