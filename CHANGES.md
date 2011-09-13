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
