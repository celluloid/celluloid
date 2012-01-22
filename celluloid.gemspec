# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'celluloid/version'

Gem::Specification.new do |gem|
  gem.name        = 'celluloid'
  gem.version     = Celluloid::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.summary     = 'Celluloid is a concurrent object framework inspired by the Actor Model'
  gem.description = gem.summary
  gem.licenses    = ['MIT']

  gem.authors     = ['Tony Arcieri']
  gem.email       = ['tony.arcieri@gmail.com']
  gem.homepage    = 'https://github.com/tarcieri/celluloid'
  
  gem.required_rubygems_version = '>= 1.3.6'
  
  gem.files        = Dir['README.md', 'lib/**/*', 'spec/support/**/*']
  gem.require_path = 'lib'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec', '~> 2.7.0'
  gem.add_development_dependency 'benchmark_suite'
end
