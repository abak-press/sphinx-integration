require "request_store"

module Sphinx
  module Integration
    class ServerStatus
      AVAILABLE_FIELD = "available".freeze

      delegate :redis, to: "self.class"

      def initialize(host)
        @host = host
      end

      def available?
        RequestStore.fetch(availability_cache_key) do
          !(redis.hget(@host, AVAILABLE_FIELD) || 1).to_i.zero?
        end
      end

      def available=(value)
        RequestStore.delete(availability_cache_key)
        redis.hset(@host, AVAILABLE_FIELD, value ? 1 : 0)
      end

      private

      def availability_cache_key
        @availability_cache_key ||= "sphinx_server_availability/#{@host}"
      end

      def self.redis
        @redis ||= Redis::Namespace.new("sphinx/integration/server_status", redis: Redis.current)
      end
    end
  end
end
