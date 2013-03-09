# coding: utf-8
module SphinxIntegration::DeltaSupport
  extend ActiveSupport::Concern

  included do
    send :include, ::Core::Extensions::ActiveRecord::AfterCommitChanges

    before_save :reset_present_in_sphinx
    before_save :reset_need_add_to_delta
    after_commit :reindex!
  end

  module InstanceMethods

    # Существует ли запись в сфинксе
    #
    # Returns Boolean
    def present_in_sphinx?
      if @present_in_sphinx.nil?
        @present_in_sphinx = !new_record? && !self.class.search_count(:with => {:sphinx_internal_id => id}, :cut_off => 1).to_i.zero?
      end

      @present_in_sphinx
    end

    # Добавить созданный товар в дельту сфинкса
    #
    # Returns nothing
    def add_to_delta_index!
      @need_add_to_delta = false
      self.class.delta_class.add(self)
    end

    # Обновить атрибуты в сфинксе
    #
    # Returns nothing
    def reindex!
      add_to_delta_index! if add_to_delta_index?

      if present_in_sphinx?
        attributes = pr_attribute_values_for_index(self.class.sphinx_default_index)
        attributes.merge!(mva_sphinx_attributes)
        update_sphinx_attributes(attributes)
      end
    end

    # Обновить атрибуты в индексах сфинкса
    #
    # attrs - Hash атрбутов
    #
    # Returns nothing
    def update_sphinx_attributes(attrs)
      attribute_names = attrs.keys
      attribute_values = attribute_names.map{|key| attrs[key] }
      attribute_names = attribute_names.map(&:to_s)
      self.class.sphinx_indexes.each do |index|
        update_index(index.core_name, attribute_names, attribute_values)
      end
      @sql_prepared_row = nil
    end

    # Обновить mva атрибуты в индексах сфинкса
    #
    # mva_method_name - String если указан, то обновит не все mva, а только заданный
    #
    # Returns nothing
    def update_mva_sphinx_attributes(mva_method_name = nil)
      if mva_method_name
        attrs = send :"mva_sphinx_attributes_for_#{mva_method_name}"
      else
        attrs = mva_sphinx_attributes
      end
      update_sphinx_attributes(attrs)
    end

    protected

    def reset_present_in_sphinx
      @present_in_sphinx = nil
    end

    def reset_need_add_to_delta
      @need_add_to_delta = false
      nil
    end

    def add_to_delta_index?
      return true if ::Blocker.full_reindex_locked?
      @need_add_to_delta ||= (before_commit_changed? && (self.class.delta_fields - before_commit_changed).size < self.class.delta_fields.size) || !present_in_sphinx?
    end

    def pr_attribute_values_for_index(index)
      self.class.sphinx_index_updatable_attrs(index).inject({}) { |hash, attrib|
        hash[attrib.unique_name.to_s] = pr_attribute_value(index, attrib)
        hash
      }
    end

    def pr_attribute_value(index, attrib)
      @sql_prepared_row ||= get_prepared_row(index)
      return pr_cast_attribute_value_to_type(attrib, @sql_prepared_row[attrib.unique_name.to_s]) if @sql_prepared_row.present?
    end

    def pr_cast_attribute_value_to_type(attrib, value)
      case attrib.type
        when :integer then value.to_i
        when :boolean then ActiveRecord::ConnectionAdapters::Column.value_to_boolean(value)
        when :float   then value.to_f
        else value
      end
    end

    def get_prepared_row(index)
      rows = self.class.connection.execute(self.class.sphinx_index_sql(index).gsub('%{ID}', id.to_s))
      return false if rows.count.zero?
      rows.first
    end

    def mva_sphinx_attributes
      attrs = {}
      self.class.methods_for_mva_attributes.each{ |m| attrs.merge! send(m) }
      attrs
    end

  end


  module ClassMethods

    # Собирает все доступные методы, которые возвращают значения для mva атрибутов
    #
    # Returns Array
    def methods_for_mva_attributes
      @methods_for_mva_attributes ||= instance_methods.select{ |m| m.to_s =~ /^mva_sphinx_attributes_for_/ }
    end

    def sphinx_default_index
      @sphinx_default_index ||= sphinx_indexes.detect{ |x| x.name == sphinx_default_index_name }
    end

    def sphinx_index_sql(index)
      return @sphinx_sql[index.name] if @sphinx_sql && @sphinx_sql[index.name]

      @sphinx_sql ||= {}

      @sphinx_sql[index.name] = sphinx_indexes.
        detect{ |x| x.name == index.name }.
        sources.
        first.
        to_sql.
        gsub(/>= \$start.*?\$end/, "= %{ID}").
        gsub(/LIMIT [0-9]+$/, '') + ' LIMIT 1'
    end

    def sphinx_index_updatable_attrs(index)
      return @sphinx_index_updatable_attrs[index.name] if @sphinx_index_updatable_attrs && @sphinx_index_updatable_attrs[index.name]
      @sphinx_index_updatable_attrs ||= {}
      @sphinx_index_updatable_attrs[index.name] = index.attributes.select { |attrib| [:integer, :boolean].include?(attrib.type) }
    end

  end

end