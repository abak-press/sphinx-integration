# coding: utf-8

require 'rubygems'
require 'bundler'

Bundler.require :default, :development

require 'sphinx/integration/railtie'

require 'mock_redis'
require 'redis-classy'

Redis::Classy.db = MockRedis.new

Combustion.initialize! :active_record

require 'rspec/rails'

RSpec.configure do |config|
  config.backtrace_exclusion_patterns = [/lib\/rspec\/(core|expectations|matchers|mocks)/]
  config.color_enabled = true
  config.order = 'random'

  config.before(:each) do
    Redis::Classy.db = MockRedis.new
  end
end
