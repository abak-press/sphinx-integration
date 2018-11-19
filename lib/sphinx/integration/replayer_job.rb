module Sphinx
  module Integration
    class ReplayerJob
      include Resque::Integration

      queue :sphinx
      unique

      def self.execute(index_name)
        replayer = ::Sphinx::Integration::Mysql::Replayer.new(
          logger: ::Sphinx::Integration::Container['logger.index_log']
        )

        replayer.replay
      end
    end
  end
end
