module Sphinx
  module Integration
    # This class stores records which updated when full reindex running.
    # Records has been removed from core index after ending reindex.
    class WasteRecords
      delegate :mysql_client, to: :"ThinkingSphinx::Configuration.instance"

      def self.for(index)
        @instances ||= {}
        @instances[index.name] ||= new(index)
      end

      def initialize(index)
        @index = index
      end

      # Add record id to set
      def add(document_id)
        Redis.current.sadd(redis_key, document_id)
      end

      # Cleanup updated records from core index
      # After that remove its from set
      def cleanup
        ids = Redis.current.smembers(redis_key)
        return if ids.blank?

        index_core_name = @index.core_name

        mysql_client
        ids.each_slice(3_000) do |slice|
          slice = slice.map!(&:to_i)
          mysql_client.soft_delete(index_core_name, slice)
        end

        reset
      end

      # Reset records set stored for index
      def reset
        Redis.current.del(redis_key)
      end

      def size
        Redis.current.scard(redis_key)
      end

      private

      def redis_key
        @redis_key ||= "sphinx:waste_records:#{@index.name}"
      end
    end
  end
end
