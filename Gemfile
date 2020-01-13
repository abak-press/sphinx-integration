source 'https://gems.railsc.ru'
source 'https://rubygems.org'

gem "riddle", git: "https://github.com/pat/riddle", branch: "develop", require: false
gem 'pg', '< 1'

# Specify your gem's dependencies in ts_customizer.gemspec
gemspec

if RUBY_VERSION < '2.3'
  gem 'pry-byebug', '< 3.7.0', require: false
  gem 'redis', '< 4.1.2', require: false
  gem 'nokogiri', '< 1.10', require: false
end

if RUBY_VERSION < '2.4'
  gem 'mock_redis', '< 0.20', require: false
  gem 'redis-namespace', '< 1.7.0', require: false
end

if RUBY_VERSION < '2.5'
  gem 'sprockets', '< 4.0.0', require: false
end
