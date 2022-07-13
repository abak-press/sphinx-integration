require 'rails'
require 'thinking-sphinx'
require 'twinkle/client'
require 'sphinx-integration'

module Sphinx::Integration
  class Railtie < Rails::Railtie
    initializer 'sphinx_integration.configuration', before: 'thinking_sphinx.sphinx' do
      ThinkingSphinx::Configuration.include Sphinx::Integration::Extensions::ThinkingSphinx::Configuration
      Riddle::Configuration::Searchd.include Sphinx::Integration::Extensions::Riddle::Configuration::Searchd

      ThinkingSphinx.database_adapter = :postgresql

      ThinkingSphinx::AutoVersion.include Sphinx::Integration::Extensions::ThinkingSphinx::AutoVersion
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
        ThinkingSphinx::PostgreSQLAdapter,
      ].each do |klass|
        klass.include "Sphinx::Integration::Extensions::#{klass.name}".constantize
      end

      ActiveSupport.on_load :active_record do
        include Sphinx::Integration::Extensions::ThinkingSphinx::ActiveRecord
      end
    end

    initializer "sphinx-integration.common", before: :load_config_initializers do |app|
      app.config.sphinx_integration = {
        socket_read_timeout_sec: nil, # not constrained by default
        vip_client_read_timeout: nil,
        rebuild: {pass_sphinx_stop: false},
        ionice_on_copy_indexes: true,
        # Custom DI container
        di: {
          loggers: {
            stdout: -> {
              logger = ::Logger.new(STDOUT)
              logger.formatter = ::Logger::Formatter.new
              logger.level = ::Logger.const_get(::ThinkingSphinx::Configuration.instance.log_level.upcase)
              logger
            },
            sphinx_file: -> {
              logger = ::Logger.new(::Rails.root.join("log", "sphinx.log"))
              logger.formatter = ::Logger::Formatter.new
              logger.level = ::Logger.const_get(::ThinkingSphinx::Configuration.instance.log_level.upcase)
              logger
            },
            indexer_file: -> {
              logger = ::Logger.new(::Rails.root.join("log", "index.log"))
              logger.formatter = ::Logger::Formatter.new
              logger.level = ::Logger::INFO
              logger
            },
          },
          error_notificator: ->(message) {
            client = ::Twinkle::Client
            client.create_message("sadness", "#{message} on #{`hostname`}", hashtags: ["#sphinx"]) if client.config.token
            client
          },
        },
      }

      app.config.sphinx_integration[:send_index_notification] = ->(subject) do
      end
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
