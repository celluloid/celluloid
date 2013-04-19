# -*- encoding: utf-8 -*-
require File.expand_path('../lib/celluloid/zmq/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tony Arcieri"]
  gem.email         = ["tony.arcieri@gmail.com"]
  gem.description   = "Celluloid bindings to the ffi-rzmq library"
  gem.summary       = "Celluloid::ZMQ provides concurrent Celluloid actors that can listen for 0MQ events"
  gem.homepage      = "http://github.com/celluloid/celluloid-zmq"

  gem.name          = "celluloid-zmq"
  gem.version       = Celluloid::ZMQ::VERSION

  gem.add_dependency "celluloid",    ">= 0.13.0"
  gem.add_dependency "ffi"
  gem.add_dependency "ffi-rzmq"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"

  # Files
  ignores = File.read(".gitignore").split(/\r?\n/).reject{ |f| f =~ /^(#.+|\s*)$/ }.map {|f| Dir[f] }.flatten
  gem.files = (Dir['**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  gem.test_files = (Dir['spec/**/*','.gitignore'] - ignores).reject {|f| !File.file?(f) }
  # gem.executables   = Dir['bin/*'].map { |f| File.basename(f) }
  gem.require_paths = ['lib']
end
