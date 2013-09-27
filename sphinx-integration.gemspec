# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sphinx/integration/version'

Gem::Specification.new do |gem|
  gem.name          = 'sphinx-integration'
  gem.version       = Sphinx::Integration::VERSION
  gem.authors       = ["merkushin"]
  gem.email         = ["merkushin.m.s@gmail.com"]
  gem.description   = %q{Sphinx Integration}
  gem.summary       = %{sphinx-integration-#{Sphinx::Integration::VERSION}}
  gem.homepage      = ''

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'redis-classy', '~> 1.2.0'
  gem.add_runtime_dependency 'redis-mutex', '~> 2.1.0'
  gem.add_runtime_dependency 'mysql2', '>= 0.2.19b5'
  gem.add_runtime_dependency 'pg'
  gem.add_runtime_dependency 'innertube'
  gem.add_runtime_dependency 'rye'
  gem.add_runtime_dependency 'riddle', '>= 1.5.8'
  gem.add_runtime_dependency 'thinking-sphinx', '= 2.0.14'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'rspec', '>= 2.14.1'
  gem.add_development_dependency 'rspec-rails', '>= 2.14.0'
  gem.add_development_dependency 'rails', '>= 3.0.3'
  gem.add_development_dependency 'combustion'
  gem.add_development_dependency 'mock_redis'
  gem.add_development_dependency 'database_cleaner'
end
