# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'celluloid/version'

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

  gem.required_rubygems_version = '>= 1.3.6'

  gem.files        = Dir['README.md', 'lib/**/*', 'spec/support/**/*']
  gem.require_path = 'lib'

  gem.add_runtime_dependency 'timers', '1.0.0.pre2'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'benchmark_suite'
end
