# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'celluloid/version'

Gem::Specification.new do |s|
  s.name        = 'celluloid'
  s.version     = Celluloid::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = 'Celluloid is a concurrent object framework inspired by the Actor Model'
  s.description = s.summary
  s.licenses    = ['MIT']

  s.authors     = ['Tony Arcieri']
  s.email       = ['tony@medioh.com']
  s.homepage    = 'https://github.com/tarcieri/celluloid'
  
  s.required_rubygems_version = '>= 1.3.6'
  
  s.files        = Dir['README.md', 'lib/**/*', 'spec/support/**/*']
  s.require_path = 'lib'

  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', ['~> 2.7.0'])
end
