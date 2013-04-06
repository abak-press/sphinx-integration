# coding: utf-8
module Sphinx::Integration::Extensions::ThinkingSphinx
  extend ActiveSupport::Concern

  included do
    DEFAULT_MATCH = :extended2
    include Sphinx::Integration::Extensions::FastFacet
  end

  module ClassMethods

    def max_matches
      @ts_max_matches ||= ThinkingSphinx::Configuration.instance.configuration.searchd.max_matches || 5000
    end

    def reset_indexed_models
      context.indexed_models.each do |model|
        model.constantize.reset_indexes
      end
    end

    def take_connection
      Sphinx::Integration::Mysql::ConnectionPool.take do |connection|
        yield connection
      end
    end

  end
end