# coding: utf-8

require 'thinking_sphinx/test'
require 'database_cleaner'

module Sphinx
  module Integration
    module Spec
      module Support
        class ThinkingSphinx
          class << self
            attr_reader :instance

            def instance
              @@instance ||= ThinkingSphinx::Support.new
            end
          end

          def reindex(opts = {})
            options = {
              :sleep => 0.25
            }.merge(opts)

            Sphinx::Integration::Helper.index
            sleep(options[:sleep])
          end

          def remote?
           ::ThinkingSphinx::Configuration.instance.remote?
          end
        end
      end
    end
  end
end

def with_sphinx(tables = nil)
  sphinx  = Sphinx::Integration::Spec::Support::ThinkingSphinx.new
  context = self

  begin
    before(:all) do
      context.use_transactional_fixtures = false
      DatabaseCleaner.strategy = :deletion, tables ? {:only => tables} : {}
    end

    before(:each) do
      time = Benchmark.realtime { DatabaseCleaner.start }
      Rails.logger.info "DatabaseCleaner started (#{time})"
    end

    after(:each) do
      time = Benchmark.realtime { DatabaseCleaner.clean }
      Rails.logger.info "DatabaseCleaner cleaned (#{time})"
    end

    yield sphinx
  ensure
    after(:all) do
      DatabaseCleaner.strategy = :transaction
      context.use_transactional_fixtures = true
    end
  end
end