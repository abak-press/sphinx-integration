module Sphinx
  module Integration
    class LastIndexingTime
      def initialize(index_name)
        raise 'Empty index name' if index_name.empty?
        @index_name = index_name
      end

      def write(time = current)
        ::Redis.current.set(redis_key, time.to_s)
      end

      def read
        value = ::Redis.current.get(redis_key) || ::Redis.current.get(old_redis_key)
        value.to_time if value
      end

      private

      def current
        ::ActiveRecord::Base.connection.select_value('select NOW()').to_time
      end

      def redis_key
        @redis_key ||= "sphinx:index:#{@index_name}:last_indexing_time"
      end

      # TODO: Remove this method after all projects will be upgraded
      def old_redis_key
        @old_redis_key ||= "ThinkingSphinx::LastIndexing:finish_time"
      end
    end
  end
end
