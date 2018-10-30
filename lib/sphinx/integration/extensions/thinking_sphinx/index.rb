module Sphinx::Integration::Extensions::ThinkingSphinx::Index
  MUTEX_EXPIRE = 43_200 # 12 hours

  extend ActiveSupport::Concern

  autoload :Builder, 'sphinx/integration/extensions/thinking_sphinx/index/builder'

  included do
    attr_accessor :merged_with_core, :is_core_index, :mva_sources

    alias_method_chain :to_riddle, :integration
    alias_method_chain :to_riddle_for_distributed, :merged
    alias_method_chain :to_riddle_for_core, :integration
    alias_method_chain :all_names, :rt
  end

  # Набор индексов для конфигурационного файла сфинкса
  #
  # offset      - Integer
  # config_type - Symbol
  #
  # Returns Array
  def to_riddle_with_integration(offset)
    return [] if merged_with_core?

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

  def rt_name(partition = nil)
    "#{name}_rt#{partition || recent_rt.current}"
  end

  def rt?
    !!@options[:rt]
  end

  def switch_rt
    recent_rt.switch
    rt.within_partition(recent_rt.prev, &:truncate)
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
  # Мы же будем возврящять только distributed индекс, чтобы воспользоваться фичей dist_threads.
  #
  # alternate индексы по умолчанию в поисковых запросах не участвуют.
  #
  # Returns Array of String
  def all_names_with_rt
    @options[:alternate] ? [] : [name]
  end

  # Карта атрибутов и их типов, нужна для типкастинга
  #
  # Returns Hash
  def attributes_types_map
    return @attributes_types_map if @attributes_types_map
    @attributes_types_map = attributes.each_with_object({}) { |attr, memo| memo[attr.unique_name.to_s] = attr.type }
  end

  def query_sql
    @query_sql ||= sources.
      first.
      to_sql(offset: model.sphinx_offset)
  end

  def mutex(lock_name)
    @mutex ||= {}
    @mutex[lock_name] ||= mutex_class.new("sphinx:index:#{name}:#{lock_name}", expire: MUTEX_EXPIRE)
  end

  def mutex_class
    @mutex_class ||= defined?(::RedisMutex) ? ::RedisMutex : ::Redis::Mutex
  end

  def indexing?
    mutex(:indexing).locked?
  end

  def indexing
    mutex(:indexing).with_lock { yield }
  end

  def recent_rt
    @recent_rt ||= ::Sphinx::Integration::RecentRt.new(name)
  end

  def last_indexing_time
    @last_indexing_time ||= ::Sphinx::Integration::LastIndexingTime.new(name)
  end

  def distributed
    @distributed ||= ::Sphinx::Integration::Statements::Distributed.new(self)
  end

  def plain
    @plain ||= ::Sphinx::Integration::Statements::Plain.new(self)
  end

  def rt
    @rt ||= ::Sphinx::Integration::Statements::Rt.new(self)
  end
end
