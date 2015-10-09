# coding: utf-8
require 'bundler'

require 'simplecov'
SimpleCov.start { minimum_coverage 85 }

require 'pry-debugger'

Bundler.require :default, :development

require 'sphinx/integration/railtie'

Combustion.initialize! :active_record

require 'rspec/rails'

require 'mock_redis'
require 'redis-classy'

Redis.current = MockRedis.new
Redis::Classy.db = Redis.current

require "support/helpers/sphinx_conf"

RSpec.configure do |config|
  include SphinxConf

  config.before(:each) do
    Redis.current.flushdb
    ThinkingSphinx::Configuration.instance.reset
  end
end
