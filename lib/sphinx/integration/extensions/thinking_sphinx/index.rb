# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Index
  extend ActiveSupport::Concern

  autoload :Builder, 'sphinx/integration/extensions/thinking_sphinx/index/builder'

  included do
    attr_accessor :merged_with_core, :is_core_index, :mva_sources
    alias_method_chain :initialize, :mutex
    alias_method_chain :to_riddle, :replication
    alias_method_chain :to_riddle_for_distributed, :merged
    alias_method_chain :to_riddle_for_core, :integration
    alias_method_chain :all_names, :rt
  end

  def initialize_with_mutex(model, &block)
    @mutex = Mutex.new
    initialize_without_mutex(model, &block)
  end

  # Набор индексов для конфигурационного файла сфинкса
  #
  # offset      - Integer
  # config_type - Symbol
  #
  # Returns Array
  def to_riddle_with_replication(offset, config_type)
    return [] if merged_with_core?

    if config_type == :master
      to_master_riddle
    else
      to_slave_riddle(offset)
    end
  end

  # Сформировать набор индесов для мастера
  #
  # Returns nothing
  def to_master_riddle
    build_read_indexes + build_write_indexes
  end

  # Сформировать набор индексов для слейва
  #
  # offset - Integer
  #
  # Returns nothing
  def to_slave_riddle(offset)
    indexes = [to_riddle_for_core(offset)]
    indexes << to_riddle_for_delta(offset) if delta?

    # найти дополнительные индексы
    merged_indexes.each do |m_index|
      indexes << m_index.send(:to_riddle_for_core, offset)
    end

    if rt?
      indexes << to_riddle_for_rt(0)
      indexes << to_riddle_for_rt(1)
    end

    indexes << to_riddle_for_distributed

    indexes
  end

  # Построить distributed индексы на чтение
  #
  # Returns Array
  def build_read_indexes
    indexes = []
    all_index_names.each do |index_name|
      indexes << (index = build_master_distributed(index_name))
      cluster = []
      config.agents.each do |name, agent|
        cluster << build_master_remote(index_name, agent)
      end
      index.mirror_indices << cluster
    end

    indexes
  end

  # Построить distributed индексы на запись
  #
  # Returns Array
  def build_write_indexes
    indexes = []
    all_index_names.each do |index_name|
      indexes << (index = build_master_distributed("#{index_name}_w"))
      config.agents.each do |name, agent|
        index.remote_indices << build_master_remote(index_name, agent)
      end
    end

    indexes
  end

  # Создать объект distributed индекс для мастера
  #
  # index_name - String
  #
  # Returns Riddle::Configuration::DistributedIndex
  def build_master_distributed(index_name)
    index = Riddle::Configuration::DistributedIndex.new(index_name)
    index.agent_connect_timeout = config.agent_connect_timeout
    index.agent_query_timeout = config.agent_query_timeout
    index.ha_strategy = 'nodeads'
    index
  end

  # Создать объект remote индекс для мастера
  #
  # index_name - String
  #
  # Returns Riddle::Configuration::RemoteIndex
  def build_master_remote(index_name, agent)
    Riddle::Configuration::RemoteIndex.new(agent['address'], agent['port'], index_name)
  end

  # Имена всех индексов
  #
  # Returns Array
  def all_index_names
    names = [name, core_name]
    names += [rt_name(0), rt_name(1)] if rt?
    names
  end

  def to_riddle_for_rt(partition)
    index = Riddle::Configuration::RealtimeIndex.new(rt_name(partition))

    set_configuration_options_for_indexes(index)

    index.path = File.join(config.searchd_file_path, index.name)
    index.rt_field = fields.map(&:unique_name)
    index.rt_mem_limit = local_options[:rt_mem_limit] if local_options[:rt_mem_limit]
    index.index_sp = local_options[:index_sp] if local_options[:index_sp]

    collect_rt_index_attributes(index)

    index
  end

  # Собрать атрибуты по типам для rt индекса
  #
  # index - Riddle::Configuration::RealtimeIndex
  #
  # Returns nothing
  def collect_rt_index_attributes(index)
    attributes.each do |attr|
      attr_type = case attr.type
      when :integer, :boolean then :rt_attr_uint
      when :bigint then :rt_attr_bigint
      when :float then :rt_attr_float
      when :datetime then :rt_attr_timestamp
      when :string then :rt_attr_string
      when :multi then :rt_attr_multi
      when :json then :rt_attr_json
      end

      index.send(attr_type) << attr.unique_name
    end
  end

  def to_riddle_for_distributed_with_merged
    index = to_riddle_for_distributed_without_merged
    merged_indexes.each do |m_index|
      index.local_indices << m_index.send(:core_name)
    end

    if rt?
      index.local_indices << rt_name(0)
      index.local_indices << rt_name(1)
    end

    index
  end

  def to_riddle_for_core_with_integration(offset)
    index = to_riddle_for_core_without_integration(offset)

    index.index_sp = local_options[:index_sp] if local_options[:index_sp]

    index
  end

  # Truncate rt index
  #
  # index_name - String
  #
  # Returns nothing
  def truncate(index_name)
    ThinkingSphinx.execute("TRUNCATE RTINDEX #{index_name}", :on_slaves => config.replication?)
  end

  def name_w
    @name_w ||= config.replication? ? "#{name}_w" : name
  end

  def core_name_w
    @core_name_w ||= config.replication? ? "#{core_name}_w" : core_name
  end

  def rt_name(partition)
    @rt_name ||= {}
    @rt_name[partition] ||= "#{name}_rt#{partition}"
  end

  def rt_name_w(partition)
    @rt_name_w ||= config.replication? ? "#{rt_name(partition)}_w" : rt_name(partition)
  end

  def rt?
    !!@options[:rt]
  end

  def merged_with_core?
    !!merged_with_core
  end

  def merged_indexes
    model.sphinx_indexes.select { |i| i.merged_with_core? }
  end

  # Перекрытый метод
  # Возращает индексы, по которым делается select
  # Оригинальынй TS зачем то перечисляет все индексы, входящие в состав distributed, зачем так делать не совсем понятно
  # Мы же будем возврящять только distributed индекс, чтобы воспользоваться фичей dist_threads
  #
  # Returns Array of String
  def all_names_with_rt
    [name]
  end

  # Карта атрибутов и их типов, нужна для типкастинга
  #
  # Returns Hash
  def attributes_types_map
    return @attributes_types_map if @attributes_types_map
    @mutex.synchronize do
      return @attributes_types_map if @attributes_types_map
      @attributes_types_map = attributes.inject({}){ |h, attr| h[attr.unique_name.to_s] = attr.type; h }
    end
  end

  def single_query_sql
    @single_query_sql ||= sources.
      first.
      to_sql(:offset => model.sphinx_offset).
      gsub(/>= \$start.*?\$end/, "= %{ID}").
      gsub(/LIMIT [0-9]+$/, '') + ' LIMIT 1'
  end
end
