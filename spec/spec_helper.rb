require 'rubygems'
require 'bundler'
#require 'rspec'
#require 'sphinx/integration'

Bundler.require :default, :development

require 'sphinx/integration/railtie'

Combustion.initialize! :active_record

require 'mock_redis'
require 'redis-classy'

RSpec.configure do |config|
  config.backtrace_clean_patterns = [/lib\/rspec\/(core|expectations|matchers|mocks)/]
  config.color_enabled = true
  config.formatter = 'documentation'
  config.order = 'random'

  config.before(:each) do
    Redis::Classy.db = MockRedis.new
  end
end