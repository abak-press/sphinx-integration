# coding: utf-8
module SphinxIntegration::Extensions::ThinkingSphinx
  extend ActiveSupport::Concern

  included do
    DEFAULT_MATCH = :extended2
    include SphinxIntegration::Extensions::FastFacet
  end

  module ClassMethods

    def max_matches
      @ts_max_matches ||= ThinkingSphinx::Configuration.instance.configuration.searchd.max_matches || 5000
    end

    def take_connection
      SphinxIntegration::Mysql::ConnectionPool.take do |connection|
        yield connection
      end
    end

  end
end