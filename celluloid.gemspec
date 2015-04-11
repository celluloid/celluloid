# -*- encoding: utf-8 -*-
require File.expand_path('../lib/celluloid/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name        = 'celluloid'
  gem.version     = Celluloid::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.summary     = 'Actor-based concurrent object framework for Ruby'
  gem.description = 'Celluloid enables people to build concurrent programs out of concurrent objects just as easily as they build sequential programs out of sequential objects'
  gem.licenses    = ['MIT']

  gem.authors     = ['Tony Arcieri']
  gem.email       = ['tony.arcieri@gmail.com']
  gem.homepage    = 'https://github.com/celluloid/celluloid'

  gem.required_ruby_version     = '>= 1.9.2'
  gem.required_rubygems_version = '>= 1.3.6'

  gem.files        = Dir['README.md', 'CHANGES.md', 'LICENSE.txt', 'lib/**/*', 'spec/**/*', 'examples/*']
  gem.require_path = 'lib'

  gem.add_runtime_dependency 'timers', '~> 4.0.0'
  gem.add_dependency 'celluloid-supervision', '~> 0.13.0'
  gem.add_development_dependency 'bundler'
end
