# frozen_string_literal: true
module Sphinx
  module Integration
    class OptimizeRtIndexJob
      RETRY_DELAY = 10.seconds
      CHECK_DELAY = 10.seconds
      RETRY_MAX_ATTEMPTS = 4
      RT_INDEX_NAME_PATTERN = /_rt\d$/.freeze
      private_constant :RT_INDEX_NAME_PATTERN, :CHECK_DELAY, :RETRY_DELAY, :RETRY_MAX_ATTEMPTS

      @queue = :cron

      class << self
        def perform(options)
          options.symbolize_keys!
          indexes = rt_indexes(options.fetch(:index))
          mutex = ::Sphinx.mutex_class.new(RT_INDEXES_PROCESS_MUTEX_KEY, expire: RT_INDEXES_PROCESS_MUTEX_TTL)
          addresses = Array.wrap(sphinx.address)

          begin
            addresses.each do |node|
              vip_client = sphinx.mysql_vip_client(node)
              disable_node(node)

              indexes.each { |index| optimize_rt_index(vip_client, index, mutex, node) }

              enable_node(node)
            end
            logger.add(::Logger::INFO, 'optimization of all rt-indexes finished')
          ensure
            addresses.each { |node| enable_node(node) }

            mutex.unlock(_force = true)
          end
        end

        private

        def rt_indexes(index)
          ::ThinkingSphinx.indexes.each_with_object([]) do |idx, memo|
            next if idx.name != index

            idx.all_index_names.each { |name| memo << name if name =~ RT_INDEX_NAME_PATTERN }
          end
        end

        def optimize_rt_index(client, index, mutex, node)
          attempt = 1

          logger.add(::Logger::INFO, "attemt ##{attempt} to optimize rt index #{index}")
          mutex.with_lock do
            client.read "OPTIMIZE INDEX #{index}"
            sleep(3)
            check_optimization_finish(client)
          end
          logger.add(::Logger::INFO, "optimize rt index #{index} complete")
        rescue ::Sphinx.mutex_lock_error_class
          logger.add(::Logger::ERROR, "optimize rt index #{index}: lock mutex error")

          if (attempt += 1) <= RETRY_MAX_ATTEMPTS
            sleep RETRY_DELAY
            retry
          end

          logger.add(::Logger::ERROR, "optimize rt index #{index}: mutex still locked")
          notificator.call("😣 optimize #{index}: mutex still locked")

          raise
        rescue StandardError => e
          msg = "😣 optimize rt index #{index} failed: #{e.message}"
          logger.add(::Logger::ERROR, msg)
          notificator.call(msg)

          raise
        end

        def check_optimization_finish(client)
          while optimize_in_process?(client)
            sleep(CHECK_DELAY)
            logger.add(::Logger::INFO, 'optimization still in process...')
          end
        end

        def optimize_in_process?(client)
          client.read('SHOW THREADS').to_a.any? { |row| row['Info'] == 'SYSTEM OPTIMIZE' }
        end

        def disable_node(node)
          sphinx_clients.each do |client|
            client.server_pool.find_server(node).server_status.available = false
          end
        end

        def enable_node(node)
          sphinx_clients.each do |client|
            client.server_pool.find_server(node).server_status.available = true
          end
        end

        def sphinx_clients
          [sphinx.client.class, sphinx.mysql_client]
        end

        def sphinx
          @sphinx ||= ::ThinkingSphinx::Configuration.instance
        end

        def logger
          @logger ||= ::Sphinx::Integration.fetch(:di)[:loggers][:indexer_file].call
        end

        def notificator
          @notificator ||= ::Sphinx::Integration.fetch(:di)[:error_notificator]
        end
      end
    end
  end
end
