# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx::Source::SQL
  extend ActiveSupport::Concern

  included do
    alias_method_chain :to_sql, :cte
    alias_method_chain :to_sql, :joins
    alias_method_chain :to_sql, :nogrouping_options
    alias_method_chain :to_sql, :limit
    alias_method_chain :to_sql, :custom_sql

    alias_method_chain :to_sql_query_range, :prepare
    alias_method_chain :to_sql_query_info, :prepared_table_name
    alias_method_chain :sql_select_clause, :prepared_table_name
  end

  module InstanceMethods

    # позволяет использовать Common Table Expressions or CTEs
    # Example
    #   set_property :source_cte => {
    #     :_contents => <<-SQL
    #       select blog_posts.id as blog_post_id, array_to_string(array_agg(blog_post_contents.content), \' \') as content
    #       from blog_posts
    #       inner join blog_post_contents on blog_post_contents.blog_post_id = blog_posts.id
    #       where {{where}}
    #       group by blog_posts.id'
    #   }
    def to_sql_with_cte(options = {})
      sql = to_sql_without_cte(options)

      if @index.local_options.key?(:source_cte)
        cte_sql = []
        @index.local_options[:source_cte].each do |name, value|
          as_sql = value.gsub('{{where}}', sql_where_clause(options)).gsub("\n", ' ')
          cte_sql << "#{name} AS (#{as_sql})"
        end

        sql = 'WITH ' + cte_sql.join(', ') + ' ' + sql unless cte_sql.empty?
      end

      sql
    end

    # Если в имени таблицы дописать _sql, то это будет считаться как джоин через подзапрос.
    # Появляются доп опции :as и :query. Скобки при этом вокруг запроса ставить не нужно
    #
    # Examples
    #
    #   set_property :source_joins => {
    #     :my_custom_join_sql => {
    #       :query => "SELECT * FROM join_table WHERE 1 = 1",
    #       :as => :my_join,
    #       :type => :inner,
    #       :on => 'my_join.id = some_table.id'
    #     }
    #   }
    #
    def to_sql_with_joins(*args)
      sql = to_sql_without_joins(*args)

      if @index.local_options.key?(:source_joins)
        join_sql = []
        @index.local_options[:source_joins].each do |join_table, join_options|
          join_table = "(#{join_options.fetch(:query, '')})" if join_options[:query]

          join_sql << "#{join_options[:type].to_s.upcase} JOIN #{join_table} AS #{join_options.fetch(:as, join_table)} ON #{join_options[:on]}"
        end
        sql.gsub!(" FROM #{model_quoted_table_name}", " FROM #{model_quoted_table_name} #{join_sql.join(' ')}") unless join_sql.empty?
      end

      sql
    end

    # NOTE Исправлена регулярка, теперь она отрезает только последний GROUP BY, а не все подряд
    def to_sql_with_nogrouping_options(*args)
      sql = to_sql_without_nogrouping_options(*args)
      sql.gsub!(/ GROUP BY [^\w\)].*$/, '') if @index.local_options.has_key?(:source_no_grouping)
      sql.gsub(@model.quoted_table_name, model_quoted_table_name)
    end

    def to_sql_with_limit(*args)
      sql = to_sql_without_limit(*args)
      sql << " LIMIT #{ @index.local_options[:sql_query_limit]}" if @index.local_options.key?(:sql_query_limit)
      sql
    end

    def to_sql_with_custom_sql(*args)
      sql = to_sql_without_custom_sql(*args)
      if @index.local_options[:with_sql] && @index.local_options[:with_sql][:select]
        sql = @index.local_options[:with_sql][:select].call(sql)
      end
      sql
    end

    def to_sql_query_range_with_prepare(options = {})
      return '' if @index.options[:disable_range] || (delta? && options[:delta] && @index.local_options[:disable_delta_range])
      return @index.local_options[:sql_query_range] if @index.local_options[:sql_query_range]
      sql = to_sql_query_range_without_prepare(options)
      sql.gsub(@model.quoted_table_name, model_quoted_table_name)
    end

    def to_sql_query_info_with_prepared_table_name(offset)
      to_sql_query_info_without_prepared_table_name(offset).gsub(@model.quoted_table_name, model_quoted_table_name)
    end

    def sql_select_clause_with_prepared_table_name(offset)
      sql_select_clause_without_prepared_table_name(offset).gsub(@model.quoted_table_name, model_quoted_table_name)
    end

    def sql_where_clause(options)
      logic = []
      unless @index.local_options[:use_own_sql_query_range]
        logic += [
          "#{model_quoted_table_name}.#{quote_column(@model.primary_key_for_sphinx)} >= $start",
          "#{model_quoted_table_name}.#{quote_column(@model.primary_key_for_sphinx)} <= $end"
        ] if (!options[:delta] && !@index.options[:disable_range]) || (self.delta? && options[:delta] && !@index.local_options[:disable_delta_range])
      end

      if self.delta? && !@index.delta_object.clause(@model, options[:delta]).blank?
        logic << "#{@index.delta_object.clause(@model, options[:delta])}"
      end

      logic += (@conditions || [])
      logic.empty? ? "" : logic.join(' AND ')
    end

    def sql_group_clause
      return @groupings.join(", ") if @index.local_options[:force_group_by]

      internal_groupings = []
      if @model.column_names.include?(@model.inheritance_column)
         internal_groupings << "#{model_quoted_table_name}.#{quote_column(@model.inheritance_column)}"
      end

      (
        ["#{model_quoted_table_name}.#{quote_column(@model.primary_key_for_sphinx)}"] +
        @fields.collect     { |field|     field.to_group_sql     }.compact +
        @attributes.collect { |attribute| attribute.to_group_sql }.compact +
        @groupings + internal_groupings
      ).join(", ")
    end

    def model_quoted_table_name
      @index.local_options.is_a?(Hash) &&
              @index.local_options.has_key?(:source_table) ?
              @model.connection.quote_table_name(@index.local_options[:source_table]) :
              @model.quoted_table_name
    end
  end
end