source 'https://gems.railsc.ru'
source 'https://rubygems.org'

gem "riddle", github: "pat/riddle", branch: "develop", require: false

if RUBY_VERSION < '2'
  gem 'pg', '< 0.19'
  gem 'mime-types', '< 3.0'
  gem 'json', '< 2.0'
  gem 'net-ssh', '< 3.0'
  gem 'pry-debugger'
else
  gem 'test-unit'
  gem 'pry-byebug'
end

# Specify your gem's dependencies in ts_customizer.gemspec
gemspec
