# frozen_string_literal: true
require "request_store"

module Sphinx
  module Integration
    class ServerStatus
      AVAILABLE_FIELD = 'available'
      BUSY_FIELD = 'busy'
      private_constant :AVAILABLE_FIELD, :BUSY_FIELD

      def initialize(host)
        @host = host
      end

      def available?
        ::RequestStore.fetch(store_availability_key) do
          !(::Redis.current.hget(redis_key, AVAILABLE_FIELD) || 1).to_i.zero?
        end
      end

      def available=(bool)
        ::RequestStore.delete(store_availability_key)
        ::Redis.current.hset(redis_key, AVAILABLE_FIELD, bool ? 1 : 0)
      end

      def busy?
        ::RequestStore.fetch(store_busyness_key) do
          !(::Redis.current.hget(store_busyness_key, BUSY_FIELD) || 1).to_i.zero?
        end
      end

      def busy=(bool)
        ::RequestStore.delete(store_busyness_key)
        ::Redis.current.hset(redis_key, BUSY_FIELD, bool ? 1 : 0)
      end

      private

      def store_busyness_key
        @store_busyness_key ||= "sphinx_server_busyness/#{@host}"
      end

      def store_availability_key
        @store_availability_key ||= "sphinx_server_availability/#{@host}"
      end

      def redis_key
        @redis_key ||= "sphinx/integration/server_status:#{@host}"
      end
    end
  end
end
