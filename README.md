# ![Celluloid](https://raw.github.com/celluloid/celluloid-logos/master/celluloid/celluloid.png)

[![Gem Version][gem-image]][gem-link] [![Build Status][build-image]][build-link] [![Code Climate][codeclimate-image]][codeclimate-link] [![Coverage Status][coverage-image]][coverage-link] [![MIT licensed][license-image]][license-link]

[gem-image]: https://badge.fury.io/rb/celluloid.svg
[gem-link]: http://rubygems.org/gems/celluloid
[build-image]: https://secure.travis-ci.org/celluloid/celluloid.svg?branch=master
[build-link]: http://travis-ci.org/celluloid/celluloid
[codeclimate-image]: https://codeclimate.com/github/celluloid/celluloid.svg
[codeclimate-link]: https://codeclimate.com/github/celluloid/celluloid)
[coverage-image]: https://coveralls.io/repos/celluloid/celluloid/badge.svg?branch=master
[coverage-link]: https://coveralls.io/r/celluloid/celluloid
[license-image]: https://img.shields.io/badge/license-MIT-blue.svg
[license-link]: https://github.com/celluloid/celluloid/blob/master/LICENSE.txt

_NOTE: This is the 0.18.x **development** branch of Celluloid. For the 0.17.x
**stable** branch, please see:_

https://github.com/celluloid/celluloid/tree/0-17-stable

> "I thought of objects being like biological cells and/or individual
> computers on a network, only able to communicate with messages"
> _--Alan Kay, creator of Smalltalk, on the meaning of "object oriented programming"_

Celluloid provides a simple and natural way to build fault-tolerant concurrent
programs in Ruby. With Celluloid, you can build systems out of concurrent
objects just as easily as you build sequential programs out of regular objects.
Recommended for any developer, including novices, Celluloid should help ease
your worries about building multithreaded Ruby programs.

## Motivation

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
  actors that are all interdependent. This means rather than worrying about
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
to EventMachine (with a synchronous API instead of callback/deferrable soup)
is available through the [Celluloid::IO](https://github.com/celluloid/celluloid-io)
library.

### Is it any good?

[Yes](http://news.ycombinator.com/item?id=3067434)

### Is It "Production Ready™"?

Yes, many users are now running Celluloid in production.

* **See:** [Projects Using Celluloid](https://github.com/celluloid/celluloid/wiki/Projects-Using-Celluloid)

## Discussion

Like Celluloid? [Join the mailing list/Google Group](http://groups.google.com/group/celluloid-ruby)
or visit us on IRC at #celluloid on freenode

## Documentation

[Please see the Celluloid Wiki](https://github.com/celluloid/celluloid/wiki)
for more detailed documentation and usage notes.

The following API documentation is also available:

* [YARD API documentation](http://rubydoc.info/gems/celluloid/frames)
* [Celluloid module (primary API)](http://rubydoc.info/gems/celluloid/Celluloid)
* [Celluloid class methods](http://rubydoc.info/gems/celluloid/Celluloid/ClassMethods)
* [All Celluloid classes](http://rubydoc.info/gems/celluloid/index)

## Related Projects

Celluloid is the parent project of a related ecosystem of other projects. If you
like Celluloid we definitely recommend you check them out:

* [Reel][reel]: An "evented" web server based on `Celluloid::IO`
* [DCell][dcell]: The Celluloid actor protocol distributed over 0MQ
* [ECell][ecell]: Mesh strategies for `Celluloid` actors distributed over 0MQ
* [Celluloid::IO][celluloid-io]: "Evented" IO support for `Celluloid` actors
* [Celluloid::ZMQ][celluloid-zmq]: "Evented" 0MQ support for `Celluloid` actors
* [Celluloid::DNS][celluloid-dns]: An "evented" DNS server based on `Celluloid::IO`
* [Celluloid::SMTP][celluloid-smtp]: An "evented" SMTP server based on `Celluloid::IO`
* [Lattice][lattice]: A concurrent realtime web framework based on `Celluloid::IO`
* [nio4r][nio4r]: "New IO for Ruby": high performance IO selectors
* [Timers][timers]: A generic Ruby timer library for event-based systems

[reel]: https://github.com/celluloid/reel/
[dcell]: https://github.com/celluloid/dcell/
[ecell]: https://github.com/celluloid/ecell/
[celluloid-io]: https://github.com/celluloid/celluloid-io/
[celluloid-zmq]: https://github.com/celluloid/celluloid-zmq/
[celluloid-dns]: https://github.com/celluloid/celluloid-dns/
[celluloid-smtp]: https://github.com/celluloid/celluloid-smtp/
[lattice]: https://github.com/celluloid/lattice/
[nio4r]: https://github.com/celluloid/nio4r/
[timers]: https://github.com/celluloid/timers/

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'celluloid'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install celluloid

Require Celluloid with:

    require 'celluloid'

### Cloning via GitHub

Right now `Celluloid` has a [submodule](https://github.com/celluloid/culture). To install the framework via GitHub, you need to clone the submodules as well.

__Clone from scratch:__

    $ git clone --recursive https://github.com/celluloid/celluloid
    
__If you  already cloned `Celluloid` without submodules:__

Run the following command in the directory containing `Celluloid`:

	git submodule update --init --recursive

## Supported Platforms

This library aims to support and is [tested against][travis] the following Ruby
versions:

* Ruby 2.2.6+
* Ruby 2.3.0+
* JRuby 9.1.6.0+

If something doesn't work on one of these versions, it's a bug.

This library may inadvertently work (or seem to work) on other Ruby versions,
however support will only be provided for the versions listed above.

If you would like this library to support another Ruby version or
implementation, you may volunteer to be a maintainer. Being a maintainer
entails making sure all tests run and pass on that implementation. When
something breaks on your implementation, you will be responsible for providing
patches in a timely fashion. If critical issues for a particular implementation
exist at the time of a major release, support for that Ruby version may be
dropped.

[travis]: http://travis-ci.org/celluloid/celluloid/

## Additional Reading

* [Concurrent Object-Oriented Programming in Python with ATOM][ATOM]
  a similar system to Celluloid written in Python

[ATOM]: http://citeseerx.ist.psu.edu/viewdoc/download;jsessionid=11A3EACE78AAFF6D6D62A64118AFCA7C?doi=10.1.1.47.5074&rep=rep1&type=pdf

## Contributing to Celluloid

* Fork this repository on github
* Make your changes and send us a pull request
* If we like them we'll merge them
* If we've accepted a patch, feel free to ask for commit access

## License

Copyright (c) 2011-2016 Tony Arcieri, Donovan Keme.

Distributed under the MIT License. See [LICENSE.txt](https://github.com/celluloid/celluloid/blob/master/LICENSE.txt)
for further details.
