module Sphinx
  module Integration
    class ReplayerJob
      include Resque::Integration

      queue :sphinx
      unique

      def self.execute(index_name)
        ::Sphinx::Integration::Mysql::Replayer.new(index_name).replay
      end
    end
  end
end
