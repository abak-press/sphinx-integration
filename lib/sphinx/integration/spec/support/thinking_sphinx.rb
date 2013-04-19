# -*- encoding : utf-8 -*-

require 'thinking_sphinx/test'
require 'database_cleaner'

class Sphinx::Integration::Spec::Support::ThinkingSphinx

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

    if remote?
      Sphinx::Integration::Helper.index
    else
      ThinkingSphinx::Test.index
    end
    sleep(options[:sleep])
  end

  def remote?
   ThinkingSphinx::Configuration.instance.remote?
  end
end

def with_sphinx(tables = nil)
  sphinx  = Sphinx::Integration::Spec::Support::ThinkingSphinx.new
  context = self

  begin
    before(:all) do
      context.use_transactional_fixtures = false
      DatabaseCleaner.strategy = :deletion, tables ? {:only => tables} : {}
      unless sphinx.remote?
        time = Benchmark.realtime do
          ThinkingSphinx::Test.create_indexes_folder
          ThinkingSphinx::Test.start
        end
        Rails.logger.info "Sphinx started (#{time})"
      end
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
      unless sphinx.remote?
        time = Benchmark.realtime { ThinkingSphinx::Test.stop }
        Rails.logger.info "Sphinx stopped (#{time})"
      end
      DatabaseCleaner.strategy = :transaction
      context.use_transactional_fixtures = true
    end
  end
end