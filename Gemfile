source 'https://gems.railsc.ru'
source 'https://rubygems.org'

gem "riddle", github: "pat/riddle", branch: "develop", require: false

if RUBY_VERSION < '2'
  gem 'pry-debugger'
else
  gem 'test-unit'
  gem 'pry-byebug'
end

# Specify your gem's dependencies in ts_customizer.gemspec
gemspec
