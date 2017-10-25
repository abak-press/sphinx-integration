module Sphinx
  module Integration
    module Mysql
      class QueryLog
        PAYLOAD_VERSION = 1
        MAXIMUM_RETRIES = 2
        REDIS_KEY = 'sphinx:query_log'.freeze

        class BaseException < StandardError; end
        class MissingPayloadVersion < BaseException; end

        def initialize(namespace: nil, retry_delay: 5)
          @namespace = namespace
          @retry_delay = retry_delay
        end

        def add(query)
          redis.rpush(redis_key, encode(query: query))
        end

        def each
          retries = 0
          last_entry = nil

          begin
            while last_entry ||= redis.lpop(redis_key)
              payload = decode(last_entry)
              yield payload.fetch(:query)

              last_entry = nil
            end
          rescue => error
            retries += 1

            if retries > MAXIMUM_RETRIES
              redis.lpush(redis_key, last_entry) if last_entry
              raise error
            else
              ::ThinkingSphinx.error "Retrying. #{error.message}"
              sleep @retry_delay
              retry
            end
          end
        end

        def reset
          redis.del(redis_key)
        end

        def size
          redis.llen(redis_key)
        end

        private

        def redis
          @redis ||= Redis.current
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
