module Sphinx
  module Integration
    module Mysql
      class QueryLog
        PAYLOAD_VERSION = 1
        ROOT_REDIS_KEY = 'sphinx:query_log'.freeze

        class BaseException < StandardError; end
        class MissingPayloadVersion < BaseException; end

        def initialize(namespace:)
          @namespace = namespace.to_s
          raise ArgumentError if @namespace.empty?
        end

        def add(payload)
          redis_client.rpush(redis_key, encode(payload))
        end

        def each_batch(batch_size:)
          key = redis_key
          redis = redis_client
          range_stop = batch_size - 1

          until (entries = redis.lrange(key, 0, range_stop)).empty?
            payloads = entries.map { |entry| decode(entry) }
            yield payloads
            redis.ltrim(key, batch_size, -1)
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
          @redis_key ||= "#{ROOT_REDIS_KEY}:#{@namespace}"
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
