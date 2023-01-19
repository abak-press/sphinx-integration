# coding: utf-8
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
  gem.homepage      = 'https://github.com/abak-press/sphinx-integration'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.metadata['allowed_push_host'] = 'https://gems.railsc.ru'

  gem.add_runtime_dependency 'activesupport', '>= 4.2.0', '< 5.0'
  gem.add_runtime_dependency 'redis-mutex', '>= 2.1'
  gem.add_runtime_dependency 'redis', '>= 3.0'
  gem.add_runtime_dependency 'mysql2', '>= 0.2.19b5'
  gem.add_runtime_dependency 'pg'
  gem.add_runtime_dependency 'innertube'
  gem.add_runtime_dependency 'rye'
  gem.add_runtime_dependency 'riddle', '>= 1.5.8'
  gem.add_runtime_dependency 'thinking-sphinx', '~> 2.0.14'
  gem.add_runtime_dependency 'net-ssh'
  gem.add_runtime_dependency 'request_store', '>= 1.2.1'
  gem.add_runtime_dependency 'twinkle-client', '>= 0.2.0'
  gem.add_runtime_dependency 'resque-integration', '>= 3.5.0'
  gem.add_runtime_dependency 'string_tools', '>= 0.9.0'

  gem.add_development_dependency 'rake', '>= 10.1.0'
  gem.add_development_dependency 'bundler', '>= 1.6'
  gem.add_development_dependency 'rails', '< 4.1'
  gem.add_development_dependency 'rspec', '>= 3.3'
  gem.add_development_dependency 'rspec-rails'
  gem.add_development_dependency 'appraisal', '>= 1.0.2'
  gem.add_development_dependency 'combustion', '>= 0.5.4'
  gem.add_development_dependency 'mock_redis'
  gem.add_development_dependency 'database_cleaner'
  gem.add_development_dependency 'rspec-collection_matchers'
  gem.add_development_dependency 'rspec-its'
  gem.add_development_dependency 'rspec-activemodel-mocks'
  gem.add_development_dependency 'simplecov'
  gem.add_development_dependency 'test-unit'
  gem.add_development_dependency 'pry-byebug'
  gem.add_development_dependency 'test_after_commit', '>= 0.2.3', '< 0.5'
end
