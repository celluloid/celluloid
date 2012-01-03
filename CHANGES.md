0.7.1
-----
* More examples!
* Cancel all pending tasks when actors crash
* Log all errors that occur during signaling failures
* Work around thread-local issues on rbx (see 52325ecd)

0.7.0
-----
* Celluloid::Task abstraction replaces Celluloid::Fiber
* Celluloid#tasks API to introspect on running tasks
* Move Celluloid::IO into its own gem, celluloid-io
* Finite state machines with Celluloid::FSM
* Fix bugs in supervisors handling actors that crash during initialize
* Old syntax Celluloid::Future() { ... } deprecated. Please use the #future
  method or Celluloid::Future.new { ... } to create futures
* New timer subsystem! Bullet point-by-bullet point details below
* Celluloid#after registers a callback to fire after a given time interval
* Celluloid.sleep and Celluloid#sleep let an actor continue processing messages
* Celluloid.receive and Celluloid#receive now accept an optional timeout
* Celluloid::Mailbox#receive now accepts an optional timeout

0.6.2
-----
* List all registered actors with Celluloid::Actor.registered
* All logging now handled through Celluloid::Logger
* Rescue DeadActorError in Celluloid::ActorProxy#inspect

0.6.1
-----
* Celluloid#links obtains Celluloid::Links for a given actor
* The #class method is now proxied to actors
* Celluloid::Fiber replaces the Celluloid.fiber and Celluloid.resume_fiber API
* Use Thread.mailbox instead of Thread.current.mailbox to obtain the mailbox
  for the current thread

0.6.0
-----
* Celluloid::Application classes for describing the structure of applications
  built with Celluloid
* Methods of actors can now participate in the actor protocol directly via
  Celluloid#receive
* Configure custom mailbox types using Celluloid.use_mailbox
* Define a custom finalizer for an actor by defining MyActor#finalize
* Actor.call and Actor.async API for making direct calls to mailboxes
* Fix bugs in Celluloid::Supervisors which would crash on startup if the actor
  they're supervising also crashes on startup
* Add Celluloid.fiber and Celluloid.resume_fiber to allow extension APIs to
  participate in the Celluloid fiber protocol

0.5.0
-----
* "include Celluloid::Actor" no longer supported. Use "include Celluloid"
* New Celluloid::IO module for actors that multiplex IO operations
* Major overhaul of Celluloid::Actor internals (see 25e22cc1)
* Actor threads are pooled in Celluloid::Actor::Pool, improving the speed
  of creating short-lived actors by over 2X
* Classes that include Celluloid now have a #current_actor instance method
* Celluloid#async allows actors to make indefinitely blocking calls while
  still responding to messages
* Fix a potential thread safety bug in Thread#mailbox
* Experimental Celluloid::TCPServer for people wanting to write servers in
  Celluloid. This may wind up in another gem, so use at your own risk!
* Magically skip ahead a few version numbers to impart the magnitude of this
  release. It's my versioning scheme and I can do what I wanna.

0.2.2
-----

* AbortErrors now reraise in caller scope and get a caller-focused backtrace
* Log failed async calls instead of just letting them fail silently
* Properly handle arity of synchronous calls
* Actors can now make async calls to themselves
* Resolve crashes that occur when sending responses to exited/dead callers

0.2.1
-----

* Hack around a bug of an indeterminate cause (2baba3d2)
* COLON!#@!

0.2.0
-----

* Support for future method calls with MyActor#future
* Initial signaling support via MyActor#signal and MyActor#wait
* Just "include Celluloid" works in lieu of "include Celluloid::Actor"
* Futures terminate implicitly when their values are obtained
* Add an underscore prefix to all of Celluloid's instance variables so they don't
  clash with user-defined ones.

0.1.0
-----
* Fiber-based reentrant actors. Requires Ruby 1.9
* MyActor.new (where MyActor includes Celluloid::Actor) is now identical to .spawn
* Terminate actors with MyActor#terminate
* Obtain current actor with Celluloid.current_actor
* Configurable logger with Celluloid.logger
* Synchronization now based on ConditionVariables instead of Celluloid::Waker
* Determine if you're in actor scope with Celluloid.actor?

0.0.3
-----
* Remove self-referential dependency in gemspec

0.0.1
-----
* Initial release
