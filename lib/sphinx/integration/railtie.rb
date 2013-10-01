# coding: utf-8

require 'rails'
require 'thinking-sphinx'
require 'sphinx-integration'

module Sphinx::Integration
  class Railtie < Rails::Railtie

    initializer 'sphinx_integration.configuration', :before => 'thinking_sphinx.set_app_root' do
      ThinkingSphinx::Configuration.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Configuration
      Riddle::Configuration::Searchd.send :include, Sphinx::Integration::Extensions::Riddle::Configuration::Searchd
    end

    initializer 'sphinx_integration.extensions', :after => 'thinking_sphinx.set_app_root' do
      [
        Riddle::Query::Insert,
        Riddle::Query::Select,
        Riddle::Configuration,
        Riddle::Configuration::DistributedIndex,
        ThinkingSphinx,
        ThinkingSphinx::Configuration,
        ThinkingSphinx::Attribute,
        ThinkingSphinx::Source,
        ThinkingSphinx::BundledSearch,
        ThinkingSphinx::Index::Builder,
        ThinkingSphinx::Property,
        ThinkingSphinx::Search,
        ThinkingSphinx::Index,
        ThinkingSphinx::PostgreSQLAdapter
      ].each do |klass|
        klass.send :include, "Sphinx::Integration::Extensions::#{klass.name}".constantize
      end

      ActiveSupport.on_load :active_record do
        include Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord
      end
    end

    rake_tasks do
      load 'sphinx/integration/tasks.rake'
    end
  end
end