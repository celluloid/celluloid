![Celluloid](https://github.com/tarcieri/celluloid/raw/master/logo.png)
=========
[![Build Status](https://secure.travis-ci.org/tarcieri/celluloid.png?branch=master)](http://travis-ci.org/tarcieri/celluloid)
[![Dependency Status](https://gemnasium.com/tarcieri/celluloid.png)](https://gemnasium.com/tarcieri/celluloid)

> "I thought of objects being like biological cells and/or individual
> computers on a network, only able to communicate with messages"
> _--Alan Kay, creator of Smalltalk, on the meaning of "object oriented programming"_

Celluloid provides a simple and natural way to build fault-tolerant concurrent
programs in Ruby. With Celluloid, you can build systems out of concurrent
objects just as easily as you build sequential programs out of regular objects.
Recommended for any developer, including novices, Celluloid should help ease
your worries about building multithreaded Ruby programs:

* __Automatic "deadlock-free" synchronization:__ Celluloid uses a
  [concurrent object model](http://python.org/workshops/1997-10/proceedings/atom/)
  which combines method dispatch with thread synchronization. Every Celluloid
  actor is a concurrent object running in its own thread, and every method
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
  fault-tolerance concepts in Erlang including [linking](https://github.com/tarcieri/celluloid/wiki/Linking),
  [supervisors](https://github.com/tarcieri/celluloid/wiki/Supervisors),
  and [supervision trees](https://github.com/tarcieri/celluloid/wiki/Groups).

* __[Futures](https://github.com/tarcieri/celluloid/wiki/futures):__
  Ever wanted to call a method "in the background" and retrieve the
  value it returns later? Celluloid futures do just that. It's like
  calling ahead to a restaurant to place an order, so they can work
  on preparing your food while you're on your way to pick it up.
  When you ask for a method's return value, it's returned immediately
  if the method has already completed, or otherwise the current method is
  suspended until the value becomes available.

You can also build distributed systems with Celluloid using its
[sister project DCell](https://github.com/tarcieri/dcell). Evented IO similar
to EventMachine (with a synchronous API) is available through the
[Celluloid::IO](https://github.com/tarcieri/celluloid-io) library.

[Please see the Celluloid Wiki](https://github.com/tarcieri/celluloid/wiki)
for more detailed documentation and usage notes.

Like Celluloid? [Join the Google Group](http://groups.google.com/group/celluloid-ruby)
or visit us on IRC at #celluloid on freenode

Supported Platforms
-------------------

Celluloid works on Ruby 1.9.2+, JRuby 1.6 (in 1.9 mode), and Rubinius 2.0. JRuby
or Rubinius are the preferred platforms as they support true hardware-level
parallelism when running Ruby code, whereas MRI/YARV is constrained by a global
interpreter lock (GIL).

To use JRuby in 1.9 mode, you'll need to pass the "--1.9" command line option
to the JRuby executable, or set the "JRUBY_OPTS=--1.9" environment variable.

Celluloid works on Rubinius in either 1.8 or 1.9 mode.

Additional Reading
------------------

* [Concurrent Object-Oriented Programming in Python with ATOM](http://python.org/workshops/1997-10/proceedings/atom/):
  ATOM implemented almost all of the same ideas as Celluloid, except it was
  written in Python (in 1997). ATOM and Celluloid are so similar that the
  ATOM paper can be considered a formal description of how Celluloid works.

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
