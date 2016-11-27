# -*- encoding: utf-8 -*-
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "celluloid/version"

Gem::Specification.new do |spec|
  spec.name        = "celluloid"
  spec.version     = Celluloid::VERSION
  spec.platform    = Gem::Platform::RUBY
  spec.licenses    = ["MIT"]
  spec.authors     = ["Tony Arcieri", "Donovan Keme"]
  spec.email       = ["bascule@gmail.com", "code@extremist.digital"]
  spec.homepage    = "https://github.com/celluloid/celluloid"
  spec.summary     = "Actor-based concurrent object framework for Ruby"
  spec.description = <<-DESCRIPTION.strip.gsub(/\s+/, " ")
    Celluloid enables people to build concurrent programs out of concurrent objects just as easily
    as they build sequential programs out of sequential objects
  DESCRIPTION

  spec.require_path = "lib"
  spec.files        = Dir["*.md", "*.txt", "lib/**/*", "spec/**/*", "examples/*"]
  spec.required_ruby_version     = ">= 2.2.6"
  spec.required_rubygems_version = ">= 2.0.0"

  spec.add_runtime_dependency "timers", "~> 4"
  spec.add_runtime_dependency "celluloid-supervision", "~> 0.20"
end
