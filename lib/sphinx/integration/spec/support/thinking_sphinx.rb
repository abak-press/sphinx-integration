# -*- encoding : utf-8 -*-

require 'thinking_sphinx/test'
require 'database_cleaner'
require 'benchmark'

class Sphinx::Integration::Spec::Support::ThinkingSphinx
  def reindex
    time = Benchmark.realtime do
      if remote?
        Core::SphinxHelper.index
      else
        ThinkingSphinx::Test.index
      end
    end
    Rails.logger.info "Sphinx reindexed (#{time})"
  end

  def remote?
    sphinx_addr = ThinkingSphinx::Configuration.instance.address
    local_addrs = Core::IpTools.internal_ips
    !local_addrs.include?(sphinx_addr)
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