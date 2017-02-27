source 'https://gems.railsc.ru'
source 'https://rubygems.org'

gem "riddle", github: "pat/riddle", branch: "develop", require: false

if RUBY_VERSION < '2'
  gem 'pry-debugger'
  gem 'dry-container', '= 0.3.4'
  gem 'dry-auto_inject', '0.3.0.1'
  gem 'dry-configurable', '< 0.6.2'
else
  gem 'test-unit'
  gem 'pry-byebug'
end

# Specify your gem's dependencies in ts_customizer.gemspec
gemspec
