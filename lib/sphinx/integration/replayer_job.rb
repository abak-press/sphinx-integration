module Sphinx
  module Integration
    class ReplayerJob
      include Resque::Integration

      queue :sphinx
      unique

      def self.execute(index_name)
        replayer = ::Sphinx::Integration::Mysql::Replayer.new(
          logger: ::Sphinx::Integration.fetch(:di)[:loggers][:indexer_file].call
        )

        replayer.replay
      end
    end
  end
end
