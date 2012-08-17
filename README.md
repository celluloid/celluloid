![Celluloid](https://raw.github.com/celluloid/celluloid-logos/master/celluloid/celluloid.png)
=========
[![Build Status](https://secure.travis-ci.org/celluloid/celluloid.png?branch=master)](http://travis-ci.org/celluloid/celluloid)
[![Dependency Status](https://gemnasium.com/celluloid/celluloid.png)](https://gemnasium.com/celluloid/celluloid)

> "I thought of objects being like biological cells and/or individual
> computers on a network, only able to communicate with messages"
> _--Alan Kay, creator of Smalltalk, on the meaning of "object oriented programming"_

Celluloid provides a simple and natural way to build fault-tolerant concurrent
programs in Ruby. With Celluloid, you can build systems out of concurrent
objects just as easily as you build sequential programs out of regular objects.
Recommended for any developer, including novices, Celluloid should help ease
your worries about building multithreaded Ruby programs.

Much of the difficulty with building concurrent programs in Ruby arises because
the object-oriented mechanisms for structuring code, such as classes and
inheritance, are separate from the concurrency mechanisms, such as threads and
locks. Celluloid combines these into a single structure, an active object
running within a thread, called an "actor", or in Celluloid vernacular, a "cell".

By combining concurrency with object oriented programming, Celluloid frees you
up from worry about where to use threads and locks. Celluloid combines them
together into a single concurrent object oriented programming model,
encapsulating state in concurrent objects and thus avoiding many of the
problems associated with multithreaded programming. Celluloid provides many
features which make concurrent programming simple, easy, and fun:

* __Automatic "deadlock-free" synchronization:__ Celluloid uses a concurrent
  object model which combines method dispatch and thread synchronization.
  Each actor is a concurrent object running in its own thread, and every method
  invocation is wrapped in a fiber that can be suspended whenever it calls
  out to other actors, and resumed when the response is available. This means
  methods which are waiting for responses from other actors, external messages,
  or other system events (including I/O with Celluloid::IO) can be suspended
  and will never block other methods that are ready to run. This won't prevent
  bugs in Celluloid, bugs in other thread-safe libraries you use, and even
  certain "dangerous" features of Celluloid from causing your program to
  deadlock, but in general, programs built with Celluloid will be naturally
  immune to deadlocks.

* __Fault-tolerance:__ Celluloid has taken to heart many of Erlang's ideas
  about fault-tolerance in order to enable self-healing applications.
  The central idea: have you tried turning it off and on again? Celluloid
  takes care of rebooting subcomponents of your application when they crash,
  whether it's a single actor, or large (potentially multi-tiered) groups of
  actors that are all interdependent. This means rather that worrying about
  rescuing every last exception, you can just sit back, relax, and let parts
  of your program crash, knowing Celluloid will automatically reboot them in
  a clean state. Celluloid provides its own implementation of the core
  fault-tolerance concepts in Erlang including [linking](https://github.com/celluloid/celluloid/wiki/Linking),
  [supervisors](https://github.com/celluloid/celluloid/wiki/Supervisors),
  and [supervision groups](https://github.com/celluloid/celluloid/wiki/Supervision-Groups).

* __[Futures](https://github.com/celluloid/celluloid/wiki/futures):__
  Ever wanted to call a method "in the background" and retrieve the
  value it returns later? Celluloid futures do just that. It's like
  calling ahead to a restaurant to place an order, so they can work
  on preparing your food while you're on your way to pick it up.
  When you ask for a method's return value, it's returned immediately
  if the method has already completed, or otherwise the current method is
  suspended until the value becomes available.

You can also build distributed systems with Celluloid using its
[sister project DCell](https://github.com/celluloid/dcell). Evented IO similar
to EventMachine (with a synchronous API) is available through the
[Celluloid::IO](https://github.com/celluloid/celluloid-io) library.

[Please see the Celluloid Wiki](https://github.com/celluloid/celluloid/wiki)
for more detailed documentation and usage notes.

Like Celluloid? [Join the Google Group](http://groups.google.com/group/celluloid-ruby)
or visit us on IRC at #celluloid on freenode

### Is It "Production Ready™"?

Yes, many users are now running Celluloid in production by using
[Sidekiq](https://github.com/mperham/sidekiq)

Installation
------------

Add this line to your application's Gemfile:

    gem 'celluloid'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install celluloid

Inside of your Ruby program do:

    require 'celluloid'

...to pull it in as a dependency.

Supported Platforms
-------------------

Celluloid works on Ruby 1.9.3, JRuby 1.6, and Rubinius 2.0. JRuby or Rubinius
are the preferred platforms as they support true thread-level parallelism when
executing Ruby code, whereas MRI/YARV is constrained by a global interpreter
lock (GIL) and can only execute one thread at a time.

Celluloid requires Ruby 1.9 mode on all interpreters. This works out of the
box on MRI/YARV, and requires the following flags elsewhere:

* JRuby: --1.9 command line option, or JRUBY_OPTS=--1.9 environment variable
* rbx: -X19 command line option

Additional Reading
------------------

* [Concurrent Object-Oriented Programming in Python with ATOM](http://python.org/workshops/1997-10/proceedings/atom/):
  a similar system to Celluloid written in Python

Contributing to Celluloid
-------------------------

* Fork this repository on github
* Make your changes and send me a pull request
* If I like them I'll merge them
* If I've accepted a patch, feel free to ask for commit access

License
-------

Copyright (c) 2012 Tony Arcieri. Distributed under the MIT License. See
LICENSE.txt for further details.
