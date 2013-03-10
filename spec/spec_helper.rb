require 'rubygems'
require 'bundler'
#require 'rspec'
#require 'sphinx_integration'

Bundler.require :default, :development

require 'sphinx_integration/railtie'

Combustion.initialize! :active_record

RSpec.configure do |config|
  config.backtrace_clean_patterns = [/lib\/rspec\/(core|expectations|matchers|mocks)/]
  config.color_enabled = true
  config.formatter = 'documentation'
  config.order = "random"
end