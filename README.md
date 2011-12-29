Celluloid::IO
=============
[![Build Status](http://travis-ci.org/tarcieri/celluloid-io.png)](http://travis-ci.org/tarcieri/celluloid-io)

You don't have to choose between threaded and evented IO! Celluloid::IO provides
a simple and easy way to wait for IO events inside of a Celluloid actor, which
runs in its own thread. Any Ruby IO object can be registered and monitored.
It's a somewhat similar idea to Ruby event frameworks like EventMachine and
Cool.io, but Celluloid actors automatically wrap up all IO in Fibers,
resulting in a synchronous API that's duck type compatible with existing IO
objects.

Unlike EventMachine, you can make as many Celluloid::IO actors as you wish,
each running their own event loop independently from the others. Using many
actors allows your program to scale across multiple CPU cores on Ruby
implementations which don't have a GIL, such as JRuby and Rubinius.

Like Celluloid::IO? [Join the Google Group](http://groups.google.com/group/celluloid-ruby)

Supported Platforms
-------------------

Celluloid works on Ruby 1.9.2+, JRuby 1.6 (in 1.9 mode), and Rubinius 2.0. JRuby
or Rubinius are the preferred platforms as they support true hardware-level
parallelism when running Ruby code, whereas MRI/YARV is constrained by a global
interpreter lock (GIL).

To use JRuby in 1.9 mode, you'll need to pass the "--1.9" command line option
to the JRuby executable, or set the "JRUBY_OPTS=--1.9" environment variable.

Celluloid works on Rubinius in either 1.8 or 1.9 mode.

Usage
-----

To use Celluloid::IO, define a normal Ruby class that includes Celluloid::IO:

    require 'celluloid/io'

	class MyServer
	  include Celluloid::IO

	  # Bind a TCP server to the given host and port
	  def initialize(host, port)
	    @server = TCPServer.new host, port
	    run!
	  end

	  # Run the TCP server event loop
	  def run
	    while true
	      wait_readable(@server)
	      on_connect @server.accept
	    end
	  end

	  # Terminate this server
	  def terminate
	    @server.close
	    super
	  end

	  # Called whenever a new connection is opened
	  def on_connect(connection)
	    connection.close
	  end
	end

Contributing to Celluloid::IO
-----------------------------

* Fork Celluloid on github
* Make your changes and send me a pull request
* If I like them I'll merge them and give you commit access to my repository

License
-------

Copyright (c) 2011 Tony Arcieri. Distributed under the MIT License. See
LICENSE.txt for further details.
