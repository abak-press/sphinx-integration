# coding: utf-8
module Sphinx::Integration::Extensions::Configuration
  extend ActiveSupport::Concern

  included do
    alias_method_chain :enforce_common_attribute_types, :rt
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