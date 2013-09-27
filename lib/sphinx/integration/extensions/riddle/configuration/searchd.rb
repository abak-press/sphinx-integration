# coding: utf-8
module Sphinx::Integration::Extensions
  module Riddle
    module Configuration
      module Searchd
        extend ActiveSupport::Concern

        included do
          attr_accessor :listen_all_interfaces
          attr_reader :remote_path

          # Базовый путь для удалённого сфинкса
          # имеется ввиду тот путь, по которому лежат подпапки logs pid data binlog
          def remote_path=(value)
            @remote_path = Pathname.new(value.to_s)
          end

          def log(with_remote = true)
            remote_path && with_remote ? remote_path.join(@log) : @log
          end

          def query_log(with_remote = true)
            with_remote = false if @query_log.to_s == '/dev/null'
            remote_path && with_remote ? remote_path.join(@query_log) : @query_log
          end

          def pid_file(with_remote = true)
            remote_path && with_remote ? remote_path.join(@pid_file) : @pid_file
          end

          def binlog_path(with_remote = true)
            remote_path && with_remote ? remote_path.join(@binlog_path) : @binlog_path
          end
        end
      end
    end
  end
end