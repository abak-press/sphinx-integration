# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Configuration
  extend ActiveSupport::Concern

  included do
    attr_accessor :remote, :replication, :agent_connect_timeout, :agent_query_timeout, :ha_strategy, :user, :password
    attr_reader :agents

    alias_method_chain :build, :integration
    alias_method_chain :generate, :integration
    alias_method_chain :config_file, :integration
    alias_method_chain :reset, :integration
    alias_method_chain :searchd_file_path, :integration
    alias_method_chain :enforce_common_attribute_types, :rt
  end

  # Находится ли sphinx на другой машине
  #
  # Returns boolean
  def remote?
    !!remote
  end

  # Включена ли репликация
  #
  # Returns boolean
  def replication?
    !!replication
  end

  def reset_with_integration(custom_app_root = nil)
    self.remote = false
    self.replication = false
    self.agents = []
    self.agent_connect_timeout = 50
    self.agent_query_timeout = 5000
    self.ha_strategy = 'nodeads'
    self.user = 'sphinx'
    @configuration.searchd.listen_all_interfaces = true

    reset_without_integration(custom_app_root)
  end

  def agents=(value)
    @agents = {}
    value.each do |name, agent|
      @agents[name] = agent.merge(:name => name).with_indifferent_access
      @agents[name][:remote_path] = Pathname.new(@agents[name][:remote_path]) if @agents[name].key?(:remote_path)
    end
  end

  # Построение конфигурационных файлов для сфинкса
  #
  # Returns nothing
  def build_with_integration
    if replication?
      generate(:master)

      agents.each do |_, agent|
        generate(:slave, agent)
      end
    else
      generate(:single)
    end
  end

  # Генерация конкретного конфига по типу
  #
  # config_type - Symbol any of [:single, :master, :slave]
  # agent       - Hash (default: nil)
  #
  # Returns nothing
  def generate_with_integration(config_type, agent = nil)
    @configuration.indices.clear

    ThinkingSphinx.context.indexed_models.each do |model|
      model = model.constantize
      model.define_indexes
      if agent
        prev_remote_path = @configuration.searchd.remote_path
        @configuration.searchd.remote_path = Pathname.new(agent[:remote_path])
      end

      @configuration.indices.concat(model.to_riddle(config_type))

      @configuration.searchd.remote_path = prev_remote_path if agent

      enforce_common_attribute_types
    end

    write_config(config_type, agent)
  end

  # Путь для файла конфигурации
  #
  # config_type - Symbol
  # agent       - Hash
  #
  # Returns String
  def config_file_with_integration(config_type, agent = nil)
    case config_type
    when :single
      "#{app_root}/config/#{environment}.sphinx.conf"
    when :master
      "#{app_root}/config/#{environment}.sphinx.master.conf"
    when :slave
      "#{app_root}/config/#{environment}.sphinx.slave-#{agent[:name]}.conf"
    else
      ArgumentError
    end
  end

  # Запись конфига в файл
  #
  # config_type - Symbol
  # agent       - Hash
  #
  # Returns nothing
  def write_config(config_type, agent)
    file_path = config_file(config_type, agent)
    open(file_path, "w") do |file|
      file.write @configuration.render(config_type, agent)
    end
  end

  def searchd_file_path_with_integration(with_remote = true)
    if @configuration.searchd.remote_path && with_remote
      @configuration.searchd.remote_path.join(@searchd_file_path)
    else
      @searchd_file_path
    end
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