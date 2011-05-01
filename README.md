Celluloid
=========

> "I thought of objects being like biological cells and/or individual 
> computers on a network, only able to communicate with messages"  
> _--Alan Kay, creator of Smalltalk, on the meaning of "object oriented programming"_

Celluloid is a concurrent object framework for Ruby inspired by Erlang and the
Actor model. Celluloid gives you thread-backed objects that run concurrently,
providing the simplicity of Ruby objects for the most common use cases, but
also the ability to call methods _asynchronously_, allowing the receiver to do
things in the background while the caller carries on with its business.
These concurrent objects are called "actors". Actors are somewhere in between
the kind of object you're typically used to working with and a network service.

Usage
-----

To use Celluloid, define a normal Ruby class that includes Celluloid::Actor

    class Sheen
      include Celluloid::Actor
  
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
    
If you call Sheen.new, you'll wind up with a plain old Ruby object. To
create a concurrent object instead of a regular one, use Sheen.spawn:

    >> charlie = Sheen.spawn "Charlie Sheen"
     => #<Celluloid::Actor(Sheen:0x00000100a312d0)>
    >> charlie.set_status "winning!"
     => "winning!" 
    >> charlie.report
     => "Charlie Sheen is winning!" 
    >> charlie.set_status! "asynchronously winning!"
     => nil 
    >> charlie.report
     => "Charlie Sheen is asynchronously winning!" 

Calling spawn creates a concurrent object running inside its own thread. You
can call methods on this concurrent object just like you would any other Ruby
object. The Sheen#set_status method works exactly like you'd expect, returning
the last expression evaluated.

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

However, you can still handle errors created by asynchronous calls using a
special features of Celluloid called _supervisors_ and _linking_.

Supervisors
-----------

You may be familiar with tools like Monit or God which keep an eye on your
applications and restart them when they crash. Celluloid supervisors work in
a similar fashion, except instead of monitoring applications, they monitor
individual actors and restart them when they crash.

To supervise an actor, start it with the _supervise_ method. Using the Sheen
class from the example above:

    >> supervisor = Sheen.supervise "Charlie Sheen"
     => #<Celluloid::Supervisor(Sheen) "Charlie Sheen">
 
This created a new Celluloid::Supervisor actor, and also created a new Sheen
actor, giving its initialize method the argument "Charlie Sheen". The 
_supervise_ method has the same method signature as _spawn_. However, rather
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
Celluloid::Actor[:charlie]. More information about the actor registry coming soon!
 
Contributing to Celluloid
-------------------------
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

Copyright
---------

Copyright (c) 2011 Tony Arcieri. See LICENSE.txt for further details.