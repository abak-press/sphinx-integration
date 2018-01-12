module Sphinx
  module Integration
    class RecentRt
      def initialize(index_name)
        raise 'Empty index name' if index_name.empty?
        @index_name = index_name
      end

      def current
        value = ::Redis.current.get(redis_key) || ::Redis.current.get(old_redis_key)
        value.to_i
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
        ::Redis.current.set(redis_key, prev)
      end

      private

      def redis_key
        @redis_key ||= "sphinx:index:#{@index_name}:recent_rt"
      end

      # TODO: Remove this method after all projects will be upgraded
      def old_redis_key
        @old_redis_key ||= "sphinx/integration/recent_rt:current"
      end
    end
  end
end
