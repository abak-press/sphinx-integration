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
          searchd(*config.start_args)
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

        def clean
          remove_files("#{config.searchd_file_path}/*")
          return unless config.configuration.searchd.binlog_path.present?
          remove_files("#{config.configuration.searchd.binlog_path}/*")
        end

        def copy_config
          return if config.config_file == config.generated_config_file
          FileUtils.mkdir_p(File.dirname(config.config_file))
          FileUtils.cp(config.generated_config_file, config.config_file)
        end

        def index(index_name)
          FileUtils.mkdir_p(config.searchd_file_path)

          if rotate?
            indexer("--rotate", index_name)
          else
            indexer(index_name)
          end
        end

        def reload
          Rye.shell(:kill, "-SIGHUP `#{config.configuration.searchd.pid_file}`")
        end

        private

        def searchd(*params)
          cmd_args = [:searchd, "--config #{config.config_file}"] + params
          logger.info Rye.shell(*cmd_args).inspect
        end

        def indexer(*params)
          logger.info Rye.shell(:indexer, "--config #{config.config_file}", *params).inspect
        end

        def remove_files(pattern)
          files = Dir.glob(pattern)
          logger.info files.join("\n")
          FileUtils.rm(files)
        end
      end
    end
  end
end
