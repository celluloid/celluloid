# -*- encoding: utf-8 -*-
require File.expand_path('../lib/celluloid/supervision/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name         = 'celluloid-supervision'
  gem.version      = Celluloid::Supervision::VERSION
  gem.platform     = Gem::Platform::RUBY
  gem.summary      = 'Celluloid Supervision'
  gem.description  = 'Supervisors, Supervision Groups, and Supervision Trees for Celluloid.'
  gem.licenses     = ['MIT']

  gem.authors      = ["Tony Arcieri", "Tim Carey-Smith", "digitalextremist //"]
  gem.email        = ['tony.arcieri@gmail.com', 'code@extremist.digital']
  gem.homepage     = 'https://github.com/celluloid/'

  gem.required_ruby_version     = '>= 1.9.2'
  gem.required_rubygems_version = '>= 1.3.6'

  gem.files        = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|examples|spec|features)/}) }
  gem.require_path = 'lib'

  gem.add_development_dependency 'bundler'
  gem.add_development_dependency 'celluloid-essentials', '>= 0.20.0.pre0'

  gem.add_development_dependency 'celluloid-supervision', '>= 0.13.9.pre0'
  gem.add_development_dependency 'celluloid-pool', '>= 0.10.0.pre0'
  gem.add_development_dependency 'celluloid-fsm', '>= 0.8.7.pre0'
end
