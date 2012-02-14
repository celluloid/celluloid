![Celluloid](https://github.com/tarcieri/celluloid-io/raw/master/logo.png)
=============
[![Build Status](https://secure.travis-ci.org/tarcieri/celluloid-io.png)](http://travis-ci.org/tarcieri/celluloid-io)
[![Dependency Status](https://gemnasium.com/tarcieri/celluloid-io.png)](https://gemnasium.com/tarcieri/celluloid-io)

You don't have to choose between threaded and evented IO! Celluloid::IO
provides a simple and easy way to wait for IO events inside of a Celluloid
actor. Underneath an event loop waits for activity on several IO objects
at once, allowing a single Celluloid::IO actor running in a single thread
to service multiple network connections simultaneously.

It's a somewhat similar idea to Ruby event frameworks like EventMachine and
Cool.io, but Celluloid actors automatically wrap up all IO in Fibers,
resulting in a synchronous API that's duck type compatible with the existing
TCPServer and TCPSocket APIs. This means you can potentially use any library
written using core Ruby IO objects with Celluloid::IO in an "evented" manner,
provided it has an API for specifying the socket classes it uses.

Celluloid::IO uses the [nio4r gem](https://github.com/tarcieri/nio4r)
to monitor IO objects, which provides access to the high-performance
epoll and kqueue system calls used by similar systems like EventMachine
and Node.js. However, where EventMachine and Node provide a singleton
"god loop" for the entire process, you can make as many Celluloid::IO actors
as you wish (system resources providing), which each run in their own
independent thread.

Using many actors allows your program to scale across multiple CPU cores on
Ruby implementations which don't have a GIL, such as JRuby and Rubinius.

Like Celluloid::IO? [Join the Google Group](http://groups.google.com/group/celluloid-ruby)

Supported Platforms
-------------------

Celluloid::IO works on Ruby 1.9.2+, JRuby 1.6 (in 1.9 mode), and Rubinius 2.0.

To use JRuby in 1.9 mode, you'll need to pass the "--1.9" command line option
to the JRuby executable, or set the "JRUBY_OPTS=--1.9" environment variable.

Usage
-----

To use Celluloid::IO, define a normal Ruby class that includes Celluloid::IO.
The following is an example of an echo server:

```ruby
require 'celluloid/io'

class EchoServer
  include Celluloid::IO

  def initialize(host, port)
    puts "*** Starting echo server on #{host}:#{port}"

    # Since we included Celluloid::IO, we're actually making a
    # Celluloid::IO::TCPServer here
    @server = TCPServer.new(host, port)
    run!
  end

  def finalize
    @server.close if @server
  end

  def run
    loop { handle_connection! @server.accept }
  end

  def handle_connection(socket)
    _, port, host = socket.peeraddr
    puts "*** Received connection from #{host}:#{port}"
    loop { socket.write socket.readpartial(4096) }
  rescue EOFError
    puts "*** #{host}:#{port} disconnected"
  end
end
```

The very first thing including *Celluloid::IO* does is also include the
*Celluloid* module, which promotes objects of this class to concurrent Celluloid
actors each running in their own thread. Before trying to use Celluloid::IO
you may want to [familiarize yourself with Celluloid in general](https://github.com/tarcieri/celluloid/).
Celluloid actors can each be thought of as being event loops. Celluloid::IO actors
are heavier but have capabilities similar to other event loop-driven frameworks.

While this looks like a normal Ruby TCP server, there aren't any threads, so
you might expect this server can only handle one connection at a time.
However, this is all you need to do to build servers that handle as many
connections as you want, and it happens all within a single thread.

The magic in this server which allows it to handle multiple connections
comes in three forms:

* __Replacement classes:__ Celluloid::IO includes replacements for the core
  TCPServer and TCPSocket classes which automatically use an evented mode
  inside of Celluloid::IO actors. They're named Celluloid::IO::TCPServer and
  Celluloid::IO::TCPSocket, so they're automatically available inside
  your class when you include Celluloid::IO.

* __Asynchronous method calls:__ You may have noticed that while the methods
  of EchoServer are named *run* and *handle_connection*, they're invoked as
  *run!* and *handle_connection!*. This queues these methods to be executed
  after the current method is complete. You can queue up as many methods as
  you want, allowing asynchronous operation similar to the "call later" or
  "next tick" feature of Twisted, EventMachine, and Node. This echo server
  first kicks off a background task for accepting connections on the server
  socket, then kicks off a background task for each connection.

* __Reactor + Fibers:__ Celluloid::IO is a combination of Actor and Reactor
  concepts. The blocking mechanism used by the mailboxes of Celluloid::IO
  actors is a [full-fledged reactor](https://github.com/tarcieri/celluloid-io/blob/master/lib/celluloid/io/reactor.rb).
  When the current task needs to make a blocking I/O call, it first makes
  a non-blocking attempt, and if the socket isn't ready the current task
  is suspended until the reactor detects the operation is ready and resumes
  the suspended task.

The result is an API for doing evented I/O that looks identical to doing
synchronous I/O. Adapting existing synchronous libraries to using evented I/O
is as simple as having them use one of Celluloid::IO's provided replacement
classes instead of the core Ruby TCPSocket and TCPServer classes.

Status
------

Celluloid::IO::TCPServer is mostly complete, although only #accept is tested
at the moment.

Celluloid::IO::TCPSocket is extremely shaky, untested, proof-of-concept code
at this point but appears to mostly work. It's partially tested by the existing
TCPServer#accept test. Real tests coming soon!

No UDP or UNIXSocket support yet. Also coming soon!

Filesystem monitoring is also likely on the horizon.

Contributing to Celluloid::IO
-----------------------------

* Fork this repository on github
* Make your changes and send me a pull request
* If I like them I'll merge them
* If I've accepted a patch, feel free to ask for a commit bit!

License
-------

Copyright (c) 2011 Tony Arcieri. Distributed under the MIT License. See
LICENSE.txt for further details.

Contains code originally from the RubySpec project also under the MIT License
Copyright (c) 2008 Engine Yard, Inc. All rights reserved.
