# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Search
  extend ActiveSupport::Concern

  included do
    alias_method_chain :populate, :logging
    alias_method_chain :query, :composite_indexes
  end

  def populate_with_logging
    unless @populated
      log "#{query}, #{options.dup.tap{|o| o[:classes] = o[:classes].map(&:name) if o[:classes] }.inspect}"
    end
    populate_without_logging
  end

  # Генерации запроса с композитными индексами
  def query_with_composite_indexes
    return @query if @query

    with_composite_index_conditions do
      query_without_composite_indexes
    end
  end

  private

  def with_composite_index_conditions
    composite_indexes = index_option(:composite_indexes) if options.key?(:conditions)

    return yield unless composite_indexes

    original_options = options
    new_options = original_options.dup
    conditions = new_options[:conditions] = new_options.fetch(:conditions).dup

    composite_indexes.each do |name, fields|
      composite_conditions = fields.keys.each_with_object([]) do |field_name, memo|
        memo << "(#{conditions.delete(field_name)})" if conditions.key?(field_name)
      end

      next if composite_conditions.empty?

      composite_conditions = composite_conditions.join(' '.freeze)
      old_composite_condition = conditions[name]

      conditions[name] =
        if old_composite_condition
          "(#{old_composite_condition}) #{composite_conditions}"
        else
          composite_conditions
        end
    end

    @options = new_options

    begin
      yield
    ensure
      @options = original_options
    end
  end
end
