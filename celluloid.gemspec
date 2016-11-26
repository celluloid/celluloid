# -*- encoding: utf-8 -*-

require File.expand_path("../culture/sync", __FILE__)

Gem::Specification.new do |gem|
  gem.name        = "celluloid"
  gem.version     = Celluloid::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.licenses    = ["MIT"]
  gem.authors     = ["Tony Arcieri", "Donovan Keme"]
  gem.email       = ["bascule@gmail.com", "code@extremist.digital"]
  gem.homepage    = "https://github.com/celluloid/celluloid"
  gem.summary     = "Actor-based concurrent object framework for Ruby"
  gem.description = <<-DESCRIPTION.strip.gsub(/\s+/, " ")
    Celluloid enables people to build concurrent programs out of concurrent objects just as easily
    as they build sequential programs out of sequential objects
  DESCRIPTION

  gem.required_ruby_version     = ">= 2.2.6"
  gem.required_rubygems_version = ">= 2.0.0"

  gem.files = Dir[
                    "README.md",
                    "CHANGES.md",
                    "LICENSE.txt",
                    "culture/**/*",
                    "lib/**/*",
                    "spec/**/*",
                    "examples/*"
                  ]

  gem.require_path = "lib"

  Celluloid::Sync::Gemspec[gem]
end
