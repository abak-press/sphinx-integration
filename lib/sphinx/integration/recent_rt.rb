require 'redis/namespace'

module Sphinx
  module Integration
    class RecentRt
      KEY_CURRENT = 'current'.freeze

      def current
        redis.get(KEY_CURRENT).to_i
      end

      def prev
        case current
        when 0
          1
        when 1
          0
        else
          raise "Unexpected current index #{current}"
        end
      end

      def switch
        redis.set(KEY_CURRENT, prev)
      end

      private

      def redis
        @redis ||= Redis::Namespace.new('sphinx/integration/recent_rt', redis: Redis.current)
      end
    end
  end
end
