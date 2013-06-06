require 'rails'
require 'thinking-sphinx'
require 'sphinx-integration'

module Sphinx::Integration
  class Railtie < Rails::Railtie

    initializer 'sphinx_integration.configuration', :before => 'thinking_sphinx.set_app_root' do
      ThinkingSphinx::Configuration.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Configuration
    end

    initializer 'sphinx_integration.extensions', :after => 'thinking_sphinx.set_app_root' do
      Riddle::Configuration::RealtimeIndex.send :include, Sphinx::Integration::Extensions::Riddle::Configuration::RealtimeIndex
      Riddle::Query::Insert.send :include, Sphinx::Integration::Extensions::Riddle::Query::Insert
      ThinkingSphinx.send :include, Extensions::ThinkingSphinx
      ThinkingSphinx::Attribute.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Attribute
      ThinkingSphinx::Source.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Source
      ThinkingSphinx::Source.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Source::SQL
      ThinkingSphinx::BundledSearch.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::BundledSearch
      ThinkingSphinx::Index::Builder.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Index::Builder
      ThinkingSphinx::Property.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Property
      ThinkingSphinx::Search.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Search
      ThinkingSphinx::Index.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Index
      ThinkingSphinx::PostgreSQLAdapter.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::PostgreSQLAdapter

      ActiveSupport.on_load :active_record do
        include Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord
      end
    end

    rake_tasks do
      load 'sphinx/integration/tasks.rake'
    end
  end
end