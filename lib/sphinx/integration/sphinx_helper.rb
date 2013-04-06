# coding: utf-8
module Sphinx::Integration
  class SphinxHelper
    module ClassMethods
      def remote_sphinx?
        sphinx_addr = ThinkingSphinx::Configuration.instance.address
        local_addrs = internal_ips

        !local_addrs.include?(sphinx_addr)
      end

      def internal_ips
        @internal_ips ||= Socket.ip_address_list.map do |addr|
          IPAddr.new(addr.ip_address.sub(/\%.*$/, ''))
        end
      end

      def config_file
        ThinkingSphinx::Configuration.instance.config_file
      end

      def sphinx_running?
        if remote_sphinx?
          `#{Rails.root}/script/sphinx --status`.present?
        else
          ThinkingSphinx.sphinx_running?
        end
      end

      def run_command(command)
        puts "System: #{command}"
        system command
      end

      def stop
        if remote_sphinx?
          run_command("#{Rails.root}/script/sphinx --stop")
        else
          run_command "searchd --config #{config_file} --stop"
        end
      end

      def start
        if remote_sphinx?
          run_command("#{Rails.root}/script/sphinx --start")
        else
          run_command "searchd --config #{config_file}"
        end
      end

      def running_start
        stop if sphinx_running?
        start
      end

      def index(online = true)
        # TODO: replace all Blocker.full_reindex
        Redis::Mutex.with_lock(:full_reindex, :expire => 3.hours) do
          if remote_sphinx?
            run_command("#{Rails.root}/script/sphinx --reindex-offline") if !online
            run_command("#{Rails.root}/script/sphinx --reindex-online")  if  online
          else
            run_command "indexer --config #{config_file} --all" if !online
            run_command "indexer --config #{config_file} --rotate --all" if online
          end
        end
      end
      alias_method :reindex, :index

      def configure
        config = ThinkingSphinx::Configuration.instance
        puts "Generating Configuration to #{config.config_file}"
        config.build
      end

      def rebuild
        Redis::Mutex.with_lock(:full_reindex, :expire => 3.hours) do
          configure

          if remote_sphinx?
            run_command("#{Rails.root}/script/sphinx --copy-config #{config_file}")
          end

          stop if sphinx_running?
          index(false)
          start
        end
      end

      def full_reindex?
        Redis::Mutex.new(:full_reindex).locked?
      end

    end

    extend ClassMethods
  end
end