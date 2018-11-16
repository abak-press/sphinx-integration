require 'bundler'

require 'simplecov'
SimpleCov.start { minimum_coverage 85 }

Bundler.require :default, :development

require 'sphinx/integration/railtie'

Combustion.initialize! :active_record, database_reset: !ENV['DATABASE_RESET'].to_s.empty?, load_schema: true do
  config.eager_load = true
end

require 'rspec/rails'

require 'mock_redis'

Redis.current = MockRedis.new
RedisClassy.redis = Redis.current
Resque.redis = Redis.current

require "support/helpers/sphinx_conf"
require "request_store"
require 'test_after_commit'

RSpec.configure do |config|
  include SphinxConf

  config.before(:each) do
    Redis.current.flushdb
    RequestStore.clear!
    ThinkingSphinx::Configuration.instance.reset
  end

  config.filter_run_including focus: true
  config.run_all_when_everything_filtered = true
end
