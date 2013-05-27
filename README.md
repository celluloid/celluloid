![Celluloid::IO](https://github.com/celluloid/celluloid-io/raw/master/logo.png)
================
[![Gem Version](https://badge.fury.io/rb/celluloid-io.png)](http://rubygems.org/gems/celluloid-io)
[![Build Status](https://secure.travis-ci.org/celluloid/celluloid-io.png?branch=master)](http://travis-ci.org/celluloid/celluloid-io)
[![Code Climate](https://codeclimate.com/github/celluloid/celluloid-io.png)](https://codeclimate.com/github/celluloid/celluloid-io)
[![Coverage Status](https://coveralls.io/repos/celluloid/celluloid-io/badge.png?branch=master)](https://coveralls.io/r/celluloid/celluloid-io)

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

Celluloid::IO uses the [nio4r gem](https://github.com/celluloid/nio4r)
to monitor IO objects, which provides cross-platform and cross-Ruby
implementation access to high-performance system calls such as epoll
and kqueue.

Like Celluloid::IO? [Join the Celluloid Google Group](http://groups.google.com/group/celluloid-ruby)

Documentation
-------------

[Please see the Celluloid::IO Wiki](https://github.com/celluloid/celluloid-io/wiki)
for more detailed documentation and usage notes.

[YARD documentation](http://rubydoc.info/github/celluloid/celluloid-io/frames)
is also available

Installation
------------

Add this line to your application's Gemfile:

    gem 'celluloid-io'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install celluloid-io

Inside of your Ruby program, require Celluloid::IO with:

    require 'celluloid/io'

Supported Platforms
-------------------

Celluloid::IO works on Ruby 1.9.3, 2.0.0, JRuby 1.6+, and Rubinius 2.0.

JRuby or Rubinius are the preferred platforms as they support true thread-level
parallelism when executing Ruby code, whereas MRI/YARV is constrained by a global
interpreter lock (GIL) and can only execute one thread at a time.

Celluloid::IO requires Ruby 1.9 mode on all interpreters.

Contributing to Celluloid::IO
-----------------------------

* Fork this repository on github
* Make your changes and send me a pull request
* If I like them I'll merge them
* If I've accepted a patch, feel free to ask for a commit bit!

License
-------

Copyright (c) 2013 Tony Arcieri. Distributed under the MIT License. See
LICENSE.txt for further details.

Contains code originally from the RubySpec project also under the MIT License.
Copyright (c) 2008 Engine Yard, Inc. All rights reserved.

Contains code originally from the 'OpenSSL for Ruby 2' project released under
the Ruby license. Copyright (C) 2001 GOTOU YUUZOU. All rights reserved.
