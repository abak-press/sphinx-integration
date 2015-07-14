# coding: utf-8

require 'rubygems'
require 'bundler'
require 'pry-debugger'

Bundler.require :default, :development

require 'sphinx/integration/railtie'

Combustion.initialize! :active_record

require 'rspec/rails'

require 'mock_redis'
require 'redis-classy'

RSpec.configure do |config|
  config.backtrace_exclusion_patterns = [/lib\/rspec\/(core|expectations|matchers|mocks)/]
  config.color_enabled = true
  config.order = 'random'

  config.before(:each) do
    Redis.current = MockRedis.new
    Redis::Classy.db = Redis.current
  end
end
