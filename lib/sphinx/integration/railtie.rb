require 'rails'
require 'thinking-sphinx'
require 'sphinx-integration'

module Sphinx::Integration
  class Railtie < Rails::Railtie

    initializer 'sphinx_integration.extensions', :after => 'thinking_sphinx.set_app_root' do
      ThinkingSphinx.send :include, Extensions::ThinkingSphinx
      ThinkingSphinx::Attribute.send :include, Sphinx::Integration::Extensions::Attribute
      ThinkingSphinx::Source.send :include, Sphinx::Integration::Extensions::Source
      ThinkingSphinx::Source.send :include, Sphinx::Integration::Extensions::Source::SQL
      ThinkingSphinx::BundledSearch.send :include, Sphinx::Integration::Extensions::BundledSearch
      ThinkingSphinx::Index::Builder.send :include, Sphinx::Integration::Extensions::Index::Builder
      ThinkingSphinx::Property.send :include, Sphinx::Integration::Extensions::Property
      ThinkingSphinx::Search.send :include, Sphinx::Integration::Extensions::Search
      ThinkingSphinx::Index.send :include, Sphinx::Integration::Extensions::Index
      ThinkingSphinx::Configuration.send :include, Sphinx::Integration::Extensions::Configuration
      ThinkingSphinx::PostgreSQLAdapter.send :include, Sphinx::Integration::Extensions::PostgreSQLAdapter

      ActiveSupport.on_load :active_record do
        include Sphinx::Integration::Extensions::ActiveRecord
      end
    end

    rake_tasks do
      load 'sphinx/integration/tasks.rake'
    end
  end
end