# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Index
  extend ActiveSupport::Concern

  autoload :Builder, 'sphinx/integration/extensions/thinking_sphinx/index/builder'

  included do
    attr_accessor :merged_with_core, :is_core_index
    alias_method_chain :to_riddle, :merged
    alias_method_chain :to_riddle_for_distributed, :merged
    alias_method_chain :all_names, :rt
  end

  def to_riddle_with_merged(offset)
    return [] if merged_with_core?

    indexes = [to_riddle_for_core(offset)]
    indexes << to_riddle_for_delta(offset) if delta?

    # найти дополнительные индексы
    merged_indexes.each do |m_index|
      indexes << m_index.send(:to_riddle_for_core, offset)
    end

    if rt?
      indexes << to_riddle_for_rt
      indexes << to_riddle_for_rt(true)
    end

    indexes << to_riddle_for_distributed

    indexes
  end

  def to_riddle_for_rt(delta = false)
    index = Riddle::Configuration::RealtimeIndex.new delta ? delta_rt_name : rt_name
    index.path = File.join config.searchd_file_path, index.name
    index.rt_field = fields.map(&:unique_name)
    attributes.each do |attr|
      attr_type = case attr.type
      when :integer, :boolean then :rt_attr_uint
      when :bigint then :rt_attr_bigint
      when :float then :rt_attr_float
      when :datetime then :rt_attr_timestamp
      when :string then :rt_attr_string
      when :multi then :rt_attr_multi
      end

      index.send(attr_type) << attr.unique_name
    end
    index
  end

  def to_riddle_for_distributed_with_merged
    index = to_riddle_for_distributed_without_merged
    merged_indexes.each do |m_index|
      index.local_indices << m_index.send(:core_name)
    end

    if rt?
      index.local_indices << rt_name
      index.local_indices << delta_rt_name
    end

    index
  end

  def rt_name
    "#{name}_rt"
  end

  def delta_rt_name
    "#{name}_delta_rt"
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

  def all_names_with_rt
    if rt?
      names = [core_name, rt_name, delta_rt_name]
    else
      names = [core_name]
    end

    names
  end

  def single_query_sql
    @single_query_sql ||= sources.
      first.
      to_sql(:offset => model.sphinx_offset).
      gsub(/>= \$start.*?\$end/, "= %{ID}").
      gsub(/LIMIT [0-9]+$/, '') + ' LIMIT 1'
  end

end