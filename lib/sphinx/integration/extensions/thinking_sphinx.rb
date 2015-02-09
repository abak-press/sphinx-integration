# coding: utf-8
require 'sphinx/integration/extensions/thinking_sphinx/indexing_mode'

module Sphinx::Integration::Extensions::ThinkingSphinx
  autoload :ActiveRecord, 'sphinx/integration/extensions/thinking_sphinx/active_record'
  autoload :Attribute, 'sphinx/integration/extensions/thinking_sphinx/attribute'
  autoload :BundledSearch, 'sphinx/integration/extensions/thinking_sphinx/bundled_search'
  autoload :Index, 'sphinx/integration/extensions/thinking_sphinx/index'
  autoload :PostgreSQLAdapter, 'sphinx/integration/extensions/thinking_sphinx/postgresql_adapter'
  autoload :Property, 'sphinx/integration/extensions/thinking_sphinx/property'
  autoload :Search, 'sphinx/integration/extensions/thinking_sphinx/search'
  autoload :Source, 'sphinx/integration/extensions/thinking_sphinx/source'
  autoload :Configuration, 'sphinx/integration/extensions/thinking_sphinx/configuration'
  autoload :LastIndexingTime, 'sphinx/integration/extensions/thinking_sphinx/last_indexing_time'

  extend ActiveSupport::Concern

  included do
    DEFAULT_MATCH = :extended2
    include Sphinx::Integration::FastFacet
    include LastIndexingTime
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

    # Посылает sql запрос в Sphinx
    #
    # query - String
    #
    # Returns Mysql2::Result|NilClass
    def execute(query, options = {})
      result = nil
      ::ThinkingSphinx::Search.log(query) do
        take_connection(options) do |connection|
          result = connection.execute(query)
        end
      end
      result
    end

    def take_connection(options = {})
      if options.fetch(:on_slaves, false)
        ::Sphinx::Integration::Mysql::ConnectionPool.take_slaves do |connection|
          yield connection
        end
      else
        Sphinx::Integration::Mysql::ConnectionPool.take do |connection|
          yield connection
        end
      end
    end

  end
end
