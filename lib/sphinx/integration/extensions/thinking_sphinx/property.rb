# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Property
  extend ActiveSupport::Concern

  included do
    alias_method_chain :available?, :allways_true
    alias_method_chain :column_available?, :allways_true
    alias_method_chain :initialize, :integration
  end

  def initialize_with_integration(source, columns, options = {})
    @source       = source
    @model        = source.model
    @columns      = Array(columns)
    @associations = {}

    if @columns.empty? || @columns.any? { |column| !column.respond_to?(:__stack) }
      raise <<-TEXT
        Cannot define a field or attribute in #{source.model.name} with no columns. Maybe you are trying to index a field with a reserved name (id, name). You can fix this error by using a symbol rather than a bare name (:id instead of id).
      TEXT
    end

    @alias        = options[:as]
    @faceted      = options[:facet]
    @admin        = options[:admin]
    @sortable     = options[:sortable] || false
    @value_source = options[:value]
    @alias        = @alias.to_sym unless @alias.blank?

    @columns.each do |col|
      a = if col.__stack.empty?
            []
          else
            association_stack(col.__stack.clone).each do |assoc|
              assoc.join_to(source.base)
            end
          end

      @associations[col.__stack] = a
    end
  end

  def available_with_allways_true?
    true
  end

  def column_available_with_allways_true?(column)
    true
  end
end
