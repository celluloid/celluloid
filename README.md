Celluloid
=========
[![Build Status](http://travis-ci.org/tarcieri/celluloid.png)](http://travis-ci.org/tarcieri/celluloid)

> "I thought of objects being like biological cells and/or individual
> computers on a network, only able to communicate with messages"
> _--Alan Kay, creator of Smalltalk, on the meaning of "object oriented programming"_

Celluloid provides a simple and natural way to build fault-tolerant concurrent
programs in Ruby. With Celluloid, you can build systems out of concurrent
objects just as easily as you build sequential programs out of regular objects.
Recommended for any developer, including novices, Celluloid should help ease
your worries about building multithreaded Ruby programs.

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

Like Celluloid? [Join the Google Group](http://groups.google.com/group/celluloid-ruby)

Supported Platforms
-------------------

Celluloid works on Ruby 1.9.2, JRuby 1.6 (in 1.9 mode), and Rubinius 2.0. JRuby
or Rubinius are the preferred platforms as they support true concurrent threads.

To use JRuby in 1.9 mode, you'll need to pass the "--1.9" command line option
to the JRuby executable, or set the "JRUBY_OPTS=--1.9" environment variable.

Celluloid works on Rubinius in either 1.8 or 1.9 mode.

Basic Usage
-----------

To use Celluloid, define a normal Ruby class that includes Celluloid:

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

Now when you create new instances of this class, they're actually concurrent
objects, each running in their own thread:

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
two features of Celluloid called _supervisors_ and _linking_. See the
corresponding sections below for more information.

Futures
-------

Futures allow you to request a computation and get the result later. There are
two types of futures supported by Celluloid: method futures and block futures.
Method futures work by invoking the _future_ method on an actor. This method
is analogous to the typical _send_ method in that it takes a method name,
followed by an arbitrary number of arguments, and a block. Let's invoke the
report method from the charlie object used in the above example using a future:

	>> future = charlie.future :report
	 => #<Celluloid::Future:0x000001009759b8>
	>> future.value
	 => "Charlie Sheen is winning!"

The call to charlie.future immediately returns a Celluloid::Future object,
regardless of how long it takes to execute the "report" method. To obtain
the result of the call to "report", we call the _value_ method of the
future object. This call will block until the value returned from the method
call is available (i.e. the method has finished executing). If an exception
occured during the method call, the call to future.value will reraise the
same exception.

Futures also allow you to background the computation of any block:

	>> future = Celluloid::Future.new { 2 + 2 }
	 => #<Celluloid::Future:0x000001008425f0>
	>> future.value
	 => 4

One thing to be aware of when using futures: always make sure to obtain the
value of any future you make. Futures create a thread in the background which
will continue to run until the future's value is obtained. Failing to obtain
the value of futures you create will leak threads.

Supervisors
-----------

You may be familiar with tools like Monit or God which keep an eye on your
applications and restart them when they crash. Celluloid supervisors work in
a similar fashion, except instead of monitoring applications, they monitor
individual actors and restart them when they crash. Crashes occur whenever
an unhandled exception is raised anywhere within an actor.

To supervise an actor, start it with the _supervise_ method. Using the Sheen
class from the example above:

    >> supervisor = Sheen.supervise "Charlie Sheen"
     => #<Celluloid::Supervisor(Sheen) "Charlie Sheen">

This created a new Celluloid::Supervisor actor, and also created a new Sheen
actor, giving its initialize method the argument "Charlie Sheen". The
_supervise_ method has the same method signature as _new_. However, rather
than returning the newly created actor, _supervise_ returns the supervisor.
To retrieve the actor that the supervisor is currently using, use the
Celluloid::Supervisor#actor method:

    >> supervisor = Sheen.supervise "Charlie Sheen"
     => #<Celluloid::Supervisor(Sheen) "Charlie Sheen">
    >> charlie = supervisor.actor
     => #<Celluloid::Actor(Sheen:0x00000100a312d0)>

Supervisors can also automatically put actors into the actor _registry_ using
the supervise_as method:

    >> Sheen.supervise_as :charlie, "Charlie Sheen"
     => #<Celluloid::Supervisor(Sheen) "Charlie Sheen">
    >> charlie = Celluloid::Actor[:charlie]
     => #<Celluloid::Actor(Sheen:0x00000100a312d0)>

In this case, the supervisor will ensure that an actor of the Sheen class,
created using the given arguments, is aways available by calling
Celluloid::Actor[:charlie]. The first argument to supervise_as is the name
you'd like the newly created actor to be registered under. The remaining
arguments are passed to initialize just like you called _new_.

See the "Registry" section below for more information on the actor registry

Linking
-------

Whenever any unhandled exceptions occur in any of the methods of an actor,
that actor crashes and dies. Let's start with an example:

    class JamesDean
      include Celluloid
      class CarInMyLaneError < StandardError; end

      def drive_little_bastard
        raise CarInMyLaneError, "that guy's gotta stop. he'll see us"
      end
    end

Now, let's have James drive Little Bastard and see what happens:

    >> james = JamesDean.new
     => #<Celluloid::Actor(JamesDean:0x1068)>
    >> james.drive_little_bastard!
     => nil
    >> james
     => #<Celluloid::Actor(JamesDean:0x1068) dead>

When we told james asynchronously to drive Little Bastard, it killed him! If
we were Elizabeth Taylor, co-star in James' latest film at the time of his
death, we'd certainly want to know when he died. So how can we do that?

Actors can _link_ to other actors they're interested in and want to receive
crash notifications from. In order to receive these events, we need to use the
trap_exit method to be notified of them. Let's look at how a hypothetical
Elizabeth Taylor object could be notified that James Dean has crashed:

    class ElizabethTaylor
      include Celluloid
      trap_exit :actor_died

      def actor_died(actor, reason)
        puts "Oh no! #{actor.inspect} has died because of a #{reason.class}"
      end
    end

We've now used the trap_exit method to configure a callback which is invoked
whenever any linked actors crashed. Now we need to link Elizabeth to James so
James' crash notifications get sent to her:

    >> james = JamesDean.new
     => #<Celluloid::Actor(JamesDean:0x11b8)>
    >> elizabeth = ElizabethTaylor.new
     => #<Celluloid::Actor(ElizabethTaylor:0x11f0)>
    >> elizabeth.link james
     => #<Celluloid::Actor(JamesDean:0x11b8)>
    >> james.drive_little_bastard!
     => nil
    Oh no! #<Celluloid::Actor(JamesDean:0x11b8) dead> has died because of a JamesDean::CarInMyLaneError

Elizabeth called the _link_ method to receive crash events from James. Because
Elizabeth was linked to James, when James crashed, James' exit message was
sent to her. Because Elizabeth was trapping the exit messages she received
using the trap_exit method, the callback she specified was invoked, allowing
her to take action (in this case, printing the error). But what would happen
if she weren't trapping exits? Let's break James apart into two separate
objects, one for James himself and one for Little Bastard, his car:

    class PorscheSpider
      include Celluloid
      class CarInMyLaneError < StandardError; end

      def drive_on_route_466
        raise CarInMyLaneError, "head on collision :("
      end
    end

    class JamesDean
      include Celluloid

      def initialize
        @little_bastard = PorscheSpider.new_link
      end

      def drive_little_bastard
        @little_bastard.drive_on_route_466
      end
    end

If you take a look in JamesDean#initialize, you'll notice that to create an
instance of PorcheSpider, James is calling the new_link method.

This method works similarly to _new_, except it combines _new_ and _link_
into a single call.

Now what happens if we repeat the same scenario with Elizabeth Taylor watching
for James Dean's crash?

    >> james = JamesDean.new
     => #<Celluloid::Actor(JamesDean:0x1108) @little_bastard=#<Celluloid::Actor(PorscheSpider:0x10ec)>>
    >> elizabeth = ElizabethTaylor.new
     => #<Celluloid::Actor(ElizabethTaylor:0x1144)>
    >> elizabeth.link james
     => #<Celluloid::Actor(JamesDean:0x1108) @little_bastard=#<Celluloid::Actor(PorscheSpider:0x10ec)>>
    >> james.drive_little_bastard!
     => nil
    Oh no! #<Celluloid::Actor(JamesDean:0x1108) dead> has died because of a PorscheSpider::CarInMyLaneError

When Little Bastard crashed, it killed James as well. Little Bastard killed
James, and because Elizabeth was trapping James' exit events, she received the
notification of James' death.

Actors that are linked together propagate their error messages to all other
actors that they're linked to. Unless those actors are trapping exit events,
those actors too will die, like James did in this case. If you have many,
many actors linked together in a large object graph, killing one will kill them
all unless they are trapping exits.

This allows you to factor your problem into several actors. If an error occurs
in any of them, it will kill off all actors used in a particular system. In
general, you'll probably want to have a supervisor start a single actor which
is in charge of a particular part of your system, and have that actor
new_link to other actors which are part of the same system. If any error
occurs in any of these actors, all of them will be killed off and the entire
subsystem will be restarted by the supervisor in a clean state.

If, for any reason, you've linked to an actor and want to sever the link,
there's a corresponding _unlink_ method to remove links between actors.

Registry
--------

Celluloid lets you register actors so you can refer to them symbolically.
You can register Actors using Celluloid::Actor[]:

    >> james = JamesDean.new
     => #<Celluloid::Actor(JamesDean:0x80c27ce0)>
    >> Celluloid::Actor[:james] = james
     => #<Celluloid::Actor(JamesDean:0x80c27ce0)>
    >> Celluloid::Actor[:james]
     => #<Celluloid::Actor(JamesDean:0x80c27ce0)>

The Celluloid::Actor constant acts as a hash, allowing you to register actors
under the name of your choosing, and access actors by name rather than
reference. This is important because actors may crash. If you're attempting to
reference an actor explicitly by storing it in a variable, you may be holding
onto a reference to a crashed copy of that actor, rather than talking to a
working, freshly-restarted version.

The main use of the registry is for interfacing with actors that are
automatically restarted by supervisors when they crash.

Signaling
---------

Signaling is an advanced technique similar to condition variables in typical
multithreaded programming. One method within a concurrent object can suspend
itself waiting for a particular event, allowing other methods to run. Another
method can then signal all methods waiting for a particular event, and even
send them a value in the process:

	class SignalingExample
	  include Celluloid
	  attr_reader :signaled

	  def initialize
	    @signaled = false
	  end

	  def wait_for_signal
	    value = wait :ponycopter
	    @signaled = true
	    value
	  end

	  def send_signal(value)
	    signal :ponycopter, value
	  end
	end

The wait_for_signal method in turn calls a method called "wait". Wait suspends
the running method until another method of the same object calls the "signal"
method with the same label.

The send_signal method of this class does just that, signaling "ponycopter"
with the given value. This value is returned from the original wait call.

Logging
-------

By default, Celluloid will log any errors and backtraces from any crashing
actors to STDOUT. However, if you wish you can use any logger which is
compatible with the standard Ruby Logger API. For example, if you're using
Celluloid within a Rails application, you'll probably want to do:

    Celluloid.logger = Rails.logger

Implementation and Gotchas
--------------------------

Celluloid is fundamentally a messaging system which uses thread-safe proxies
to manage all inter-object communication in the system. While the goal of
these proxies is to make it simple for you to write concurrent programs by
applying the uniform access principle to thread-safe inter-object messaging,
you can't simply forget they're there.

The thread-safety guarantees Celluloid provides around synchronizing access to
instance variables only work so long as all access to actors go through the
proxy objects. If the real objects that Celluloid is wrapping in an actor
manage to leak out of the system, all hell will break loose.

Here are a few rules you can follow to keep this from happening:

1. ***NEVER RETURN SELF*** (or pass self as an argument to other actors): in
   cases where you want to pass an actor around to other actors or threads,
   use Celluloid.current_actor. If you grab the latest master of Celluloid
   off of Github, you can just use the #current_actor method when you are
   inside of an actor itself.

2. Don't mutate the state of objects you've sent in calls to other actors:
   This means you must think about data in one of two different ways: either
   you "fire and forget" the data, leaving it for other actors to do with
   what they will, or you must treat it as immutable if you have any plans
   of sharing it with other actors. If you're paranoid (and when you're
   dealing with concurrency, there's nothing wrong with being paranoid),
   you can freeze objects so you can detect subsequent mutations (or rather,
   turn attempts at mutation into errors).

3. Don't mix Ruby thread primitives and calls to other actors: if you make
   a call to another actor with a mutex held, you're doing it wrong. It's
   perfectly fine and strongly encouraged to call out to thread safe
   libraries from Celluloid actors. However, if you're using libraries that
   acquire mutexes and then execute callbacks (e.g. they take a block while
   they're holding a mutex) the guarantees that Celluloid provides will
   become weak and you may encounter deadlocks.

4. Use Fibers at your own risk: Celluloid employs Fibers as an intrinsic part
   of how it implements actors. While it's possible for certain uses of Fibers
   to cooperatively work alongside how Celluloid behaves, in most cases you'll
   be writing a check you can't afford. So please ask yourself: why are you
   using Fibers, and why can't it be solved by a block? If you've got a really
   good reason and you're feeling lucky, knock yourself out.

On Thread Safety in Ruby
------------------------

Ruby actually has a pretty good story when it comes to thread safety. The best
strategy for thread safety is to share as little state as possible, and if
you do share state, you should never mutate it. The worry of anyone stepping
into a thread safe world is that you're using a bunch of legacy libraries with
dubious thread safety. Who knows what those crazy library authors were doing?

Relax people. You're using a language where somebody can change what the '+'
operator does to numbers. So why aren't we afraid to add numbers? Who knows
what those crazy library authors may have done! Instead of freaking out, we
can learn some telltale signs of things that will cause thread safety problems
in Ruby programs so we can identify potential problem libraries just from how
their APIs behave.

The #1 thread safety issue to look out for in a Ruby library is if it provides
some sort of singleton access to a particular object through a class method,
e.g MyClass.zomgobject, as opposed to asking you do do MyClass.new. If you
aren't allocating the object, it isn't yours, it's somebody else's, and you
better damn well make sure you can share nice, or you shouldn't play with it
at all.

How do we share nicely? Let's find out by first looking at a thread-unsafe
version of a singleton method:

    class Foo
      def self.current
        @foo ||= Foo.new
      end
    end

Seems bad. All threads will share access to the same Foo object, and there's
also a secondary bug here which means when the object is first being allocated
and memoized as @foo. The first thread that tries to allocate it may get a
different version than all the other threads because the memo value it set
got clobbered by another thread because it's unsynchronized.

What else can we do? It depends on why the library is memoizing. Perhaps the
Foo object has some kind of setup cost, such as making a network connection,
and we want to keep it around instead of setting it up and tearing it down
every time. If that's the case, the simplest thing we can do to make this
code thread safe is to create a thread-specific memo of the object:

    class Foo
      def self.current
        Thread.current[:foo] ||= Foo.new
      end
    end

Keep in mind that this will require N Foo objects for N threads. If each
object is wrapping a network connection, this might be a concern. That said,
if you see this pattern employed in the singleton methods of a library,
it's most likely thread safe, provided that Foo doesn't do other wonky things.

Contributing to Celluloid
-------------------------

* Fork Celluloid on github
* Make your changes and send me a pull request
* If I like them I'll merge them and give you commit access to my repository

Copyright
---------

Copyright (c) 2011 Tony Arcieri. See LICENSE.txt for further details.
