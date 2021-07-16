require "rye"

module Sphinx
  module Integration
    module HelperAdapters
      class SshProxy
        DEFAULT_SSH_OPTIONS = {
          user: "sphinx",
          port: 22,
          quiet: false,
          info: true,
          safe: false,
          debug: false,
          forward_agent: true,
          password_prompt: false
        }.freeze

        delegate :file_upload, to: "@servers"

        # options - Hash
        #           :hosts             - Array of String (required)
        #           :port              - Integer ssh port (default: 22)
        #           :user              - String (default: sphinx)
        #           :password          - String (optional)
        def initialize(options = {})
          @options = options
          @servers = Rye::Set.new("servers", parallel: true)

          ssh_options = options.slice(:user, :port, :password).select { |_, value| !value.nil? }

          Array.wrap(options.fetch(:hosts)).each do |host|
            server = Rye::Box.new(host, DEFAULT_SSH_OPTIONS.merge(ssh_options))
            server.stdout_hook = proc { |data| data.to_s.split("\n").each { |msg| logger.info(msg) } }
            server.pre_command_hook = proc { |cmd, *| logger.info(cmd) }
            @servers.add_box(server)
          end
        end

        def within(host)
          removed_servers = []
          @servers.boxes.keep_if { |server| server.host == host || (removed_servers << server && false) }
          yield
          @servers.boxes.concat(removed_servers)
        end

        def without(host)
          index = @servers.boxes.index { |x| x.host == host }
          server = @servers.boxes.delete_at(index)
          yield server
          @servers.boxes.insert(index, server)
        end

        def execute(*args)
          options = args.extract_options!
          exit_status = Array.wrap(options.fetch(:exit_status, 0))
          raps = @servers.execute(*args)
          has_errors = false

          raps.each do |rap|
            real_status = rap[0].is_a?(::Rye::Err) ? rap[0].exit_status : rap.exit_status
            unless exit_status.include?(real_status)
              logger.error(rap.inspect)
              has_errors ||= true
            end
          end
          raise "Error in executing #{args.inspect}" if has_errors
        end

        def logger
          @logger = @options[:logger] || ::Sphinx::Integration.fetch(:di)[:loggers][:stdout].call
        end
      end

      class Remote < Base
        AVG_CLOSE_CONNECTIONS_TIME = 10.seconds
        DEFAULT_ROTATION_TIME = 10.seconds
        private_constant :AVG_CLOSE_CONNECTIONS_TIME, :DEFAULT_ROTATION_TIME

        def initialize(*)
          super

          @ssh = SshProxy.new(hosts: hosts,
                              port: config.ssh_port,
                              user: config.user,
                              password: config.ssh_password,
                              logger: logger)
        end

        def running?
          !!@ssh.execute("searchd", "--config #{config.config_file}", "--status")
        rescue Rye::Err
          false
        end

        def stop
          @ssh.execute("searchd", "--config #{config.config_file}", "--stopwait")
        end

        def start
          args = ["searchd", "--config #{config.config_file}"] + config.start_args
          @ssh.execute(*args)
        end

        def suspend
          hosts.each { |host| disable_host(host) }
        end

        def resume
          hosts.each { |host| enable_host(host) }
        end

        def restart
          suspend
          # Wait for all request to be complete
          sleep(3)
          stop
          start
          resume
        end

        def clean
          remove_files("#{config.searchd_file_path}/*")
          return unless config.configuration.searchd.binlog_path.present?

          remove_files("#{config.configuration.searchd.binlog_path}/*")
        end

        def copy_config
          @ssh.file_upload(config.generated_config_file, config.config_file)
          sql_file = Rails.root.join("config", "sphinx.sql")
          @ssh.file_upload(sql_file.to_s, config.configuration.searchd.sphinxql_state) if sql_file.exist?
        end

        def index(idx)
          exec_indexer(idx.core_name)
          copy_indexes if hosts.many?

          reload(idx) if rotate?
        end

        # Public: gentle rotation indexes
        #
        # Returns nil
        def reload(idx)
          logger.info "Rotation #{idx.core_name}"

          waiting_duration = idx.local_options[:rotation_time] || DEFAULT_ROTATION_TIME

          hosts.each do |host|
            @ssh.within(host) { sighup }

            sleep(waiting_duration)
          end
        end

        private

        def sighup
          @ssh.execute('kill', "-SIGHUP `cat #{config.configuration.searchd.pid_file}`")
          logger.info 'SIGHUP sent'
        end

        def indexer_args
          args = ["--config #{config.config_file}"]
          args.concat(%w(--rotate --nohup)) if rotate?
          args
        end

        def exec_indexer(index_name)
          @ssh.within(reindex_host) do
            @ssh.execute("indexer", *indexer_args, index_name, exit_status: [0, 2])

            if rotate?
              @ssh.execute("for NAME in #{config.searchd_file_path}/*_#{CORE_POSTFIX}.tmp.*; " +
                           'do mv -f "${NAME}" "${NAME/\.tmp\./.new.}"; done')
            end
          end
        end

        def copy_indexes
          files = "#{config.searchd_file_path}/*_#{CORE_POSTFIX}#{'.new' if rotate?}.*"

          @ssh.without(reindex_host) do |server|
            @ssh.execute(
              'ionice -c3 rsync',
              '-ptzv',
              '--bwlimit=70M',
              '--compress-level=1',
              '--rsync-path="ionice -c3 rsync"',
              "-e 'ssh -p #{server.opts[:port]}'",
              "#{server.user}@#{server.host}:#{files} #{config.searchd_file_path}"
            )
          end
        end

        def hosts
          return @hosts if @hosts

          @hosts = Array.wrap(config.address)
          @hosts = @hosts.select { |host| @options[:host] == host } if @options[:host].presence
          @hosts
        end

        def remove_files(pattern)
          @ssh.execute("rm", "-f", pattern)
        end

        def reindex_host
          @reindex_host ||= hosts.first
        end

        def disable_host(host)
          logger.info "Disable host #{host}"

          config.client.class.server_pool.find_server(host).server_status.available = false
          config.mysql_client.server_pool.find_server(host).server_status.available = false

          sleep(AVG_CLOSE_CONNECTIONS_TIME)
        end

        def enable_host(host)
          logger.info "Enable host #{host}"

          config.client.class.server_pool.find_server(host).server_status.available = true
          config.mysql_client.server_pool.find_server(host).server_status.available = true
        end
      end
    end
  end
end
