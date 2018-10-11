require 'rails'
require 'thinking-sphinx'
require 'twinkle/client'
require 'sphinx-integration'

module Sphinx::Integration
  class Railtie < Rails::Railtie
    initializer "sphinx_integration.sphinx", before: "thinking_sphinx.sphinx" do
      ThinkingSphinx::AutoVersion.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::AutoVersion
    end

    initializer 'sphinx_integration.configuration', :before => 'thinking_sphinx.set_app_root' do
      ThinkingSphinx::Configuration.send :include, Sphinx::Integration::Extensions::ThinkingSphinx::Configuration
      ThinkingSphinx.database_adapter = :postgresql
    end

    initializer 'sphinx_integration.extensions', :after => 'thinking_sphinx.set_app_root' do
      [
        Riddle::Query::Insert,
        Riddle::Query::Select,
        Riddle::Client,
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

    initializer "sphinx-integration.common", before: :load_config_initializers do |app|
      ::Sphinx::Integration::Container.namespace("logger") do
        register "stdout", -> do
          logger = ::Logger.new(STDOUT)
          logger.formatter = ::Logger::Formatter.new
          logger.level = ::Logger.const_get(::ThinkingSphinx::Configuration.instance.log_level.upcase)
          logger
        end

        register "sphinx_log", -> do
          logger = ::Logger.new(::Rails.root.join("log", "sphinx.log"))
          logger.formatter = ::Logger::Formatter.new
          logger.level = ::Logger.const_get(::ThinkingSphinx::Configuration.instance.log_level.upcase)
          logger
        end

        register "index_log", -> do
          logger = ::Logger.new(::Rails.root.join("log", "index.log"))
          logger.formatter = ::Logger::Formatter.new
          logger.level = ::Logger::INFO
          logger
        end

        register "notificator", ->(message) do
          client = ::Twinkle::Client
          client.create_message("sadness", "#{message} on #{`hostname`}", hashtags: ["#sphinx"]) if client.config.token
        end
      end

      app.config.sphinx_integration = {rebuild: {pass_sphinx_stop: false}}
    end

    initializer 'sphinx_integration.rspec' do
      if defined?(::RSpec::Core)
        RSpec.configure do |c|
          c.before(:each) do |example|
            unless example.metadata.fetch(:with_sphinx, false)
              Sphinx::Integration::Transmitter.write_disabled = true
            end
          end

          c.after(:each) do |example|
            if example.metadata.fetch(:with_sphinx, false)
              ::ThinkingSphinx.rt_indexes.each do |index|
                index.rt.truncate
              end
            else
              Sphinx::Integration::Transmitter.write_disabled = false
            end
          end
        end
      end
    end

    config.after_initialize do
      ThinkingSphinx.context.define_indexes
    end

    rake_tasks do
      load 'sphinx/integration/tasks.rake'
    end
  end
end
