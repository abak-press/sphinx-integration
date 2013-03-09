require 'sphinx_integration'
require 'rails'

module SphinxIntegration
  class Railtie < Rails::Railtie

    initializer 'sphinx_integration.extensions', :after => 'thinking_sphinx.set_app_root' do
      ThinkingSphinx.send :include, Extensions::ThinkingSphinx
      ThinkingSphinx::Attribute.send :include, SphinxIntegration::Extensions::Attribute
      ThinkingSphinx::Source.send :include, SphinxIntegration::Extensions::Source
      ThinkingSphinx::Source.send :include, SphinxIntegration::Extensions::Source::SQL
      ThinkingSphinx::BundledSearch.send :include, SphinxIntegration::Extensions::BundledSearch
      ThinkingSphinx::Index::Builder.send :include, SphinxIntegration::Extensions::Index::Builder
      ThinkingSphinx::Property.send :include, SphinxIntegration::Extensions::Property
      ThinkingSphinx::Search.send :include, SphinxIntegration::Extensions::Search
      ThinkingSphinx::Index.send :include, SphinxIntegration::Extensions::Index
      ThinkingSphinx::Configuration.send :include, SphinxIntegration::Extensions::Configuration
      ThinkingSphinx::PostgreSQLAdapter.send :include, SphinxIntegration::Extensions::PostgreSQLAdapter

      ActiveSupport.on_load :active_record do
        include SphinxIntegration::Extensions::ActiveRecord
      end
    end

    rake_tasks do
      load File.expand_path('../tasks.rb', __FILE__)
    end
  end
end