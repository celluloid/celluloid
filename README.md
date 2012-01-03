Celluloid
=========
[![Build Status](http://travis-ci.org/tarcieri/celluloid.png)](http://travis-ci.org/tarcieri/celluloid) [![Dependency Status](https://gemnasium.com/tarcieri/celluloid.png)](https://gemnasium.com/tarcieri/celluloid)

> "I thought of objects being like biological cells and/or individual
> computers on a network, only able to communicate with messages"
> _--Alan Kay, creator of Smalltalk, on the meaning of "object oriented programming"_

Celluloid provides a simple and natural way to build fault-tolerant concurrent
programs in Ruby. With Celluloid, you can build systems out of concurrent
objects just as easily as you build sequential programs out of regular objects.
Recommended for any developer, including novices, Celluloid should help ease
your worries about building multithreaded Ruby programs:

* __Look ma, no mutexes:__ Celluloid automatically synchronizes access to instance
  variables by using a special proxy object system and messaging model.
* __[Futures](https://github.com/tarcieri/celluloid/wiki/futures):__
  Ever wanted to call a method "in the background" and retrieve the
  value it returns later? Celluloid futures allow you to do that. When you
  ask for a method's return value it's returned if it's immediately available
  or blocks if the method is still running.
* __[Supervisors](https://github.com/tarcieri/celluloid/wiki/supervisors):__
  Celluloid can monitor your concurrent objects and
  automatically restart them when they crash. You can also link concurrent
  objects together into groups that will crash and restart as a group,
  ensuring that after a crash all interdependent objects are in a clean and
  consistent state.

Under the hood, Celluloid wraps regular objects in threads that talk to each
other using messages. These concurrent objects are called "actors". When a
caller wants another actor to execute a method, it literally sends it a
message object telling it what method to execute. The receiver listens on its
mailbox, gets the request, runs the method, and sends the caller the result.
The receiver processes messages in its inbox one-at-a-time, which means that
you don't need to worry about synchronizing access to an object's instance
variables.

In addition to that, Celluloid also gives you the ability to call methods
_asynchronously_, so the receiver to do things in the background for you
without the caller having to sit around waiting for the result.

You can also build distributed systems with Celluloid using its
[sister project DCell](https://github.com/tarcieri/dcell).

[Please see the Celluloid Wiki](https://github.com/tarcieri/celluloid/wiki)
for more detailed documentation and usage notes.

Like Celluloid? [Join the Google Group](http://groups.google.com/group/celluloid-ruby)

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

To use Celluloid, define a normal Ruby class that includes Celluloid:

```ruby
require 'celluloid'

class Sheen
  include Celluloid

  def initialize(name)
    @name = name
  end

  def set_status(status)
    @status = status
  end

  def report
    "#{@name} is #{@status}"
  end
end
```

Now when you create new instances of this class, they're actually concurrent
objects, each running in their own thread:

```ruby
>> charlie = Sheen.new "Charlie Sheen"
 => #<Celluloid::Actor(Sheen:0x00000100a312d0) @name="Charlie Sheen">
>> charlie.set_status "winning!"
 => "winning!"
>> charlie.report
 => "Charlie Sheen is winning!"
>> charlie.set_status! "asynchronously winning!"
 => nil
>> charlie.report
 => "Charlie Sheen is asynchronously winning!"
```

You can call methods on this concurrent object just like you would any other
Ruby object. The Sheen#set_status method works exactly like you'd expect,
returning the last expression evaluated.

However, Celluloid's secret sauce kicks in when you call banged predicate
methods (i.e. methods ending in !). Even though the Sheen class has no
set_status! method, you can still call it. Why is this? Because bang methods
have a special meaning in Celluloid. (Note: this also means you can't define
bang methods on Celluloid classes and expect them to be callable from other
objects)

Adding a bang to the end of a method instructs Celluloid that you would like
for the given method to be called _asynchronously_. This means that rather
than the caller waiting for a response, the caller sends a message to the
concurrent object that you'd like the given method invoked, and then the
caller proceeds without waiting for a response. The concurrent object
receiving the message will then process the method call in the background.

Adding a bang to a method name is a convention in Ruby used to indicate that
the method is in some way "dangerous", and in Celluloid this is no exception.
You have no guarantees that just because you made an asynchronous call it was
ever actually invoked. Asynchronous calls will never raise an exception, even
if an exception occurs when the receiver is processing it. Worse, unhandled
exceptions will crash the receiver, and making an asynchronous call to a
crashed object will not raise an error.

However, you can still handle errors created by asynchronous calls using
two features of Celluloid called [supervisors](https://github.com/tarcieri/celluloid/wiki/supervisors)
and [linking](https://github.com/tarcieri/celluloid/wiki/linking)

[Please see the Celluloid Wiki](https://github.com/tarcieri/celluloid/wiki)
for additional usage information.

Contributing to Celluloid
-------------------------

* Fork Celluloid on github
* Make your changes and send me a pull request
* If I like them I'll merge them and give you commit access to my repository

License
-------

Copyright (c) 2011 Tony Arcieri. Distributed under the MIT License. See
LICENSE.txt for further details.
