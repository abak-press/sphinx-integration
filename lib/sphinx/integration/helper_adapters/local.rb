require "rye"

module Sphinx
  module Integration
    module HelperAdapters
      class Local < Base
        def running?
          ThinkingSphinx.sphinx_running?
        end

        def stop
          searchd("--stopwait")
        end

        def start
          searchd
        end

        def suspend
          # no-op
        end

        def resume
          # no-op
        end

        def restart
          stop
          start
        end

        def remove_indexes
          remove_files("#{config.searchd_file_path}/*_{core,rt0,rt1}.*")
        end

        def remove_binlog
          return unless config.configuration.searchd.binlog_path.present?
          remove_files("#{config.configuration.searchd.binlog_path}/binlog.*")
        end

        def copy_config
          # no-op
        end

        def index(online)
          online ? indexer("--rotate") : indexer
        end

        def reload
          Rye.shell(:kill, "-SIGHUP `#{config.configuration.searchd.pid_file}`")
        end

        private

        def searchd(*params)
          log Rye.shell(:searchd, "--config #{config.config_file}", *params).inspect
        end

        def indexer(*params)
          log Rye.shell(:indexer, "--config #{config.config_file} --all", *params).inspect
        end

        def remove_files(pattern)
          files = Dir.glob(pattern)
          log files.join("\n")
          FileUtils.rm(files)
        end
      end
    end
  end
end
