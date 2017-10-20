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
require 'redis-classy'

Redis.current = MockRedis.new
Redis::Classy.db = Redis.current

require "support/helpers/sphinx_conf"
require "request_store"

RSpec.configure do |config|
  include SphinxConf

  config.before(:each) do
    Redis.current.flushdb
    RequestStore.clear!
    ThinkingSphinx::Configuration.instance.reset
  end
end
