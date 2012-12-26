![Celluloid](https://github.com/celluloid/celluloid-io/raw/master/logo.png)
=============
[![Build Status](https://secure.travis-ci.org/celluloid/celluloid-io.png?branch=master)](http://travis-ci.org/celluloid/celluloid-io)
[![Dependency Status](https://gemnasium.com/celluloid/celluloid-io.png)](https://gemnasium.com/celluloid/celluloid-io)
[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/celluloid/celluloid-io)

You don't have to choose between threaded and evented IO! Celluloid::IO
provides an event-driven IO system for building fast, scalable network
applications that integrates directly with the
[Celluloid actor library](https://github.com/celluloid/celluloid), making it
easy to combine both threaded and evented concepts. Celluloid::IO is ideal for
servers which handle large numbers of mostly-idle connections, such as Websocket
servers or chat/messaging systems.

Celluloid::IO provides a different class of actor: one that's slightly slower
and heavier than standard Celluloid actors, but one which contains a
high-performance reactor just like EventMachine or Cool.io. This means
Celluloid::IO actors have the power of both Celluloid actors and evented
I/O loops. Unlike certain other evented I/O systems which limit you to a
single event loop per process, Celluloid::IO lets you make as many actors as
you want, system resources permitting.

Rather than callbacks, Celluloid::IO exposes a synchronous API built on duck
types of Ruby's own IO classes, such as TCPServer and TCPSocket. These classes
work identically to their core Ruby counterparts, but in the scope of
Celluloid::IO actors provide "evented" performance. Since they're drop-in
replacements for the standard classes, there's no need to rewrite every
library just to take advantage of Celluloid::IO's event loop and you can
freely switch between evented and blocking IO even over the lifetime of a
single connection.

Celluloid::IO uses the [nio4r gem](https://github.com/tarcieri/nio4r)
to monitor IO objects, which provides cross-platform and cross-Ruby
implementation access to high-performance system calls such as epoll
and kqueue.

Like Celluloid::IO? [Join the Google Group](http://groups.google.com/group/celluloid-ruby)

When should I use Celluloid::IO?
--------------------------------

Unlike systems like Node.js, Celluloid does not require that all I/O be
"evented". Celluloid fully supports any libraries that support blocking I/O
and for the *overwhelming majority* of use cases blocking I/O is more than
sufficient. Using blocking I/O means that any Ruby library you want will
Just Work without resorting to any kind of theatrics.

Celluloid::IO exists for a few reasons:

* During a blocking I/O operation, Celluloid actors cannot respond to incoming
  messages to their mailboxes. They will process messages as soon as the
  method containing a blocking I/O operation completes, however until this
  happens the entire actor is blocked. If you would like to multiplex both
  message processing and I/O operations, you will want to use Celluloid::IO.
  This is especially important for *indefinite* blocking operations, such as
  listening for incoming TCP connections.
* Celluloid uses a native thread per actor. While native threads aren't
  particularly expensive in Ruby (~20kB of RAM), you can use less RAM using
  Celluloid::IO. You might consider using Celluloid::IO over an 
  actor-per-connection if you are dealing with 10,000 connections or more.
* The goal of Celluloid::IO is to fully integrate it into the Celluloid
  ecosystem, including DCell. DCell will hopefully eventually support
  serializable I/O handles that you can seamlessly transfer between nodes.

All that said, if you are just starting out with Celluloid, you probably want
to start off using blocking I/O until you understand the fundamentals of
Celluloid and have encountered one of the above reasons for switching
over to Celluloid::IO.

Supported Platforms
-------------------

Celluloid::IO requires Ruby 1.9 support on all Ruby VMs.

Supported VMs are Ruby 1.9.3, JRuby 1.6, and Rubinius 2.0.

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
you may want to [familiarize yourself with Celluloid in general](https://github.com/celluloid/celluloid/).
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
  actors is an [nio4r-powered reactor](https://github.com/celluloid/celluloid-io/blob/master/lib/celluloid/io/reactor.rb).
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

The rudiments of TCPServer and TCPSocket are in place and ready to use. It is now
fully nonblocking, including DNS resolution, which effectively makes Celluloid::IO
feature complete as a nonblocking I/O system.

Basic UDPSocket support is in place. On JRuby, recvfrom makes a blocking call
as the underlying recvfrom_nonblock call is not supported by JRuby.

No UNIXSocket support yet, sorry (patches welcome!)

Contributing to Celluloid::IO
-----------------------------

* Fork this repository on github
* Make your changes and send me a pull request
* If I like them I'll merge them
* If I've accepted a patch, feel free to ask for a commit bit!

License
-------

Copyright (c) 2012 Tony Arcieri. Distributed under the MIT License. See
LICENSE.txt for further details.

Contains code originally from the RubySpec project also under the MIT License
Copyright (c) 2008 Engine Yard, Inc. All rights reserved.
