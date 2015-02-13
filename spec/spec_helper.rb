# coding: utf-8

require 'rubygems'
require 'bundler'

Bundler.require :default, :development

require 'sphinx/integration/railtie'

Combustion.initialize! :active_record

require 'rspec/rails'

require 'mock_redis'

RSpec.configure do |config|
  config.backtrace_exclusion_patterns = [/lib\/rspec\/(core|expectations|matchers|mocks)/]
  config.color_enabled = true
  config.order = 'random'

  config.before(:each) do
    Redis.current = MockRedis.new
  end
end
