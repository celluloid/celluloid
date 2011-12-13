# -*- encoding: utf-8 -*-
require File.expand_path('../lib/celluloid/zmq/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tony Arcieri"]
  gem.email         = ["tony.arcieri@gmail.com"]
  gem.description   = "Celluloid bindings to the ffi-rzmq library"
  gem.summary       = "Celluloid::ZMQ provides concurrent Celluloid actors that can listen for 0MQ events"
  gem.homepage      = "http://github.com/tarcieri/dcell"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "celluloid-zmq"
  gem.require_paths = ["lib"]
  gem.version       = Celluloid::ZMQ::VERSION

  gem.add_dependency "celluloid", ">= 0.6.2"
  gem.add_dependency "ffi"
  gem.add_dependency "ffi-rzmq"
  gem.add_dependency "redis"
  gem.add_dependency "redis-namespace"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec", ">= 2.7.0"
end
