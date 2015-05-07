# -*- encoding: utf-8 -*-

require File.expand_path("../culture/sync", __FILE__)

Gem::Specification.new do |gem|
  gem.name         = "celluloid-supervision"
  gem.version      = Celluloid::Supervision::VERSION
  gem.platform     = Gem::Platform::RUBY
  gem.summary      = "Celluloid Supervision"
  gem.description  = "Supervisors, Supervision Groups, and Supervision Trees for Celluloid."
  gem.licenses     = ["MIT"]

  gem.authors      = ["digitalextremist //", "Tony Arcieri", "Tim Carey-Smith"]
  gem.email        = ["code@extremist.digital", "tony.arcieri@gmail.com"]
  gem.homepage     = "https://github.com/celluloid/"

  gem.required_ruby_version     = ">= 1.9.2"
  gem.required_rubygems_version = ">= 1.3.6"

  gem.files        = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|examples|spec|features)/}) }
  gem.require_path = "lib"

  Celluloid::Sync::Gemspec[gem]
end
