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
