# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Configuration
  extend ActiveSupport::Concern

  included do
    attr_accessor :remote, :user, :password, :exclude, :ssh_port,
                  :log_level, :mysql_read_timeout, :mysql_connect_timeout

    alias_method_chain :shuffled_addresses, :integration
    alias_method_chain :reset, :integration
    alias_method_chain :enforce_common_attribute_types, :rt

    def initial_model_directories
      []
    end
  end

  def mysql_client
    return @mysql_client if @mysql_client

    port = configuration.searchd.mysql41
    port = 9306 if port.is_a?(TrueClass)
    @mysql_client = Sphinx::Integration::Mysql::Client.new(shuffled_addresses, port)
  end

  def shuffled_addresses_with_integration
    Array.wrap(address)
  end

  # Находится ли sphinx на другой машине
  #
  # Returns boolean
  def remote?
    !!remote
  end

  def reset_with_integration(custom_app_root = nil)
    self.remote = false
    self.user = 'sphinx'
    self.exclude = []
    self.log_level = "fatal"
    self.mysql_connect_timeout = 2
    self.mysql_read_timeout = 5
    self.ssh_port = 22
    @mysql_client = nil

    reset_without_integration(custom_app_root)

    return if @configuration.searchd.binlog_path
    @configuration.searchd.binlog_path = "#{app_root}/db/sphinx/#{environment}"
  end

  def generated_config_file
    Rails.root.join("config", "#{Rails.env}.sphinx.conf").to_s
  end

  # Не проверям на валидность RT индексы
  # Метод пришлось полностью переписать
  def enforce_common_attribute_types_with_rt
    sql_indexes = configuration.indices.reject do |index|
      index.is_a?(Riddle::Configuration::DistributedIndex) ||
        index.is_a?(Riddle::Configuration::RealtimeIndex)
    end

    return unless sql_indexes.any? { |index|
      index.sources.any? { |source|
        source.sql_attr_bigint.include? :sphinx_internal_id
      }
    }

    sql_indexes.each { |index|
      index.sources.each { |source|
        next if source.sql_attr_bigint.include? :sphinx_internal_id

        source.sql_attr_bigint << :sphinx_internal_id
        source.sql_attr_uint.delete :sphinx_internal_id
      }
    }
  end
end
