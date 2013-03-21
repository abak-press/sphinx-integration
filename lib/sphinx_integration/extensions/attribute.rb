# coding: utf-8
module SphinxIntegration::Extensions::Attribute
  extend ActiveSupport::Concern

  included do
    alias_method_chain :initialize, :query_option
    alias_method_chain :source_value, :custom_query
  end

  def initialize_with_query_option(source, columns, options = {})
    @query = options[:query]
    initialize_without_query_option(source, columns, options)
  end

  def available?
    true
  end

  def source_value_with_custom_query(offset, delta)
    if is_string?
      return "#{query_source.to_s.dasherize}; #{columns.first.__name}"
    end

    if query_source == :ranged_query
      if @query.present?
        query = @query.gsub(/\{\{([a-zA-Z0-9_.]+)\}\}/, "\\1 #{ThinkingSphinx.unique_id_expression(adapter, offset)}")
        "ranged-query; #{query}"
      else
        query = query(offset)
        query += query_clause
        query += " AND #{query_delta.strip}" if delta
        "ranged-query; #{query}; #{range_query}"
      end
    else
      if @query.present?
        query = @query.gsub(/\{\{([a-zA-Z0-9_.]+)\}\}/, "\\1 #{ThinkingSphinx.unique_id_expression(adapter, offset)}")
        "query; #{query}"
      else
        query = query(offset)
        query += "WHERE #{query_delta.strip}" if delta
        "query; #{query}"
      end
    end
  end

end