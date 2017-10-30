module Sphinx
  module Integration
    module Mysql
      class QueryLog
        PAYLOAD_VERSION = 1
        REDIS_KEY = 'sphinx:query_log'.freeze

        class BaseException < StandardError; end
        class MissingPayloadVersion < BaseException; end

        def initialize(namespace: nil)
          @namespace = namespace
        end

        def add(query)
          redis_client.rpush(redis_key, encode(query: query))
        end

        def each_batch(limit: 50)
          key = redis_key
          redis = redis_client
          range_stop = limit - 1

          until (entries = redis.lrange(key, 0, range_stop)).empty?
            queries = entries.map { |entry| decode(entry).fetch(:query) }
            yield queries
            redis.ltrim(key, limit, -1)
          end
        end

        def reset
          redis_client.del(redis_key)
        end

        def size
          redis_client.llen(redis_key)
        end

        private

        def redis_client
          @redis_client ||= Redis.current
        end

        def redis_key
          @redis_key ||=
            if @namespace
              "#{REDIS_KEY}:#{@namespace}".freeze
            else
              REDIS_KEY
            end
        end

        def encode(payload)
          payload[:version] = PAYLOAD_VERSION
          Marshal.dump(payload)
        end

        def decode(string)
          payload = Marshal.load(string)
          raise MissingPayloadVersion if payload.fetch(:version) != PAYLOAD_VERSION
          payload
        end
      end
    end
  end
end
