0.17.3 (2016-01-18)
-----
* [#701](https://github.com/celluloid/celluloid/pull/701)
  Conditions in loose threads loop does not take into account the difference between
  backtraces from ruby 2.0.0 and greater than. Fixes celluloid/celluloid-io#165.
  ([@TiagoCardoso1983])

* [#700](https://github.com/celluloid/celluloid/pull/700)
  Set celluloid logger level to info by default unless debug is enabled. Fixes #667.
  ([@ioquatix])

* [#695](https://github.com/celluloid/celluloid/pull/695)
  Extending the condition event handler with the block; this solves a bug
  introduced in jruby >9.0.0.0, which breaks with an ArgumentError exception,
  apparently due to the way to_proc procs are passed arguments. Fixes #694.
  ([@TiagoCardoso1983])

* [#689](https://github.com/celluloid/celluloid/pull/689)
  Simplified sync, async and future proxies by providing specific AbstractCall base.
  ([@ioquatix])

* [#688](https://github.com/celluloid/celluloid/pull/688)
  Fix failure to remove dead actors from sets, e.g. celluloid-supervision.
  ([@ioquatix])

* [#686](https://github.com/celluloid/celluloid/pull/686)
  Print out method name to help debugging method call which caused dead actor error.
  ([@ioquatix])

* [#682](https://github.com/celluloid/celluloid/pull/682)
  Remove excess call/block require.

* [#666](https://github.com/celluloid/celluloid/pull/666)
  Don't catch IOError.

0.17.2 (2015-09-30)
-----
* Revamped test suite, using shared RSpec configuration layer provided by Celluloid itself.
* Updated gem dependencies provided by Celluloid::Sync... extraneous gems removed, or marked as development dependencies.
* Clean up deprecation notes.

0.17.1.2 (2015-08-21)
-----
* Fixes to posted markdown content.
* Pull in new gem dependencies.

0.17.1.1 (2015-08-07)
-----
* Revert "no task to suspend" code from #232.

0.17.1 (2015-08-06)
-----
* `Celluloid::ActorSystem` moved to `Celluloid::Actor::System`, and from `celluloid/actor_system.rb` to `celluloid/actor/system.rb`
* Added extensible API for defining new SystemEvents, and having them handled... without everyone changing `Actor#handle_system_event`.
* Deprecated Task::TerminatedError & Task::TimeoutError... Consolidated in exceptions.rb, inherited from Exceptions vs. StandardError.
* General round-up of all "errors" emitted throughout Celluloid, to either be derived from `Celluloid::Error` or `Celluloid::Interruption`.
* Added ability to pass a block to `Condition#wait` which runs a `{ |value| ... }` type block if present, once the value is obtained by waiting.

0.17.0 (2015-07-04)
-----
* Fix $CELLULOID_TEST warnings
* Massive overhaul of test suite, end-to-end.
* Make "Terminating task" log messages debug-level events
* Added `.dead?` method on actors, as opposite of `.alive?`
* Added class/module method to access `publish` outside actors.
* Radical Refactor of Celluloid::InternalPool, and moved it to Celluloid::Group::Pool
* Radical Refactor: *::Group::Pool replaced as default with *::Group::Spawner
* Added `rspec-log_split` as replacement logger for itemized testing logs.
* *::Task::PooledFibers has been found and made available, and compatible ( sometimes 4x faster than even Task::Fibered )
* GEM EXTRACTION: PoolManager taken out, and implemented in the `celluloid-pool` gem, separately.
* GEM EXTRACTION: FSM taken out, and implemented in the `celluloid-fsm` gem, separately.
* GEM EXTRACTION: SupervisionGroup, Supervisor, and related methods taken out, and implemented in the `celluloid-supervision` gem, separately.
* BREAKING CHANGE: Added Celluloid::Internals and moved several "private" classes into that namespace:
  * CallChain, CPUCounter, Handlers ( and Handle ), Links, Logger, Method, Properties, Registry, Responses, Signals, StackDump, TaskSet, ThreadHandle, UUID.
* BREAKING CHANGE: Changed class names, per convention:
  * Moved Celluloid::TaskFiber to Celluloid::Task::Fibered
  * Moved Celluloid::TaskThread to Celluloid::Task::Threaded
  * Moved Celluloid::EventedMailbox to Celluloid::Mailbox::Evented
  * Moved Celluloid::AbstractProxy to Celluloid::Proxy::Abstract
  * Moved Celluloid::ActorProxy to Celluloid::Proxy::Actor
  * Moved Celluloid::AsyncProxy to Celluloid::Proxy::Async
  * Moved Celluloid::BlockProxy to Celluloid::Proxy::Block
  * Moved Celluloid::CellProxy to Celluloid::Proxy::Cell
  * Moved Celluloid::FutureProxy to Celluloid::Proxy::Future
  * Moved Celluloid::SyncProxy to Celluloid::Proxy::Sync
* GEM EXTRACTION: `Internals`, `Notifications`, `Probe`, and the contents of `logging/*` have become a `celluloid-essentials` gem.
* Implement `Group::Manager` as base for future `Group::Unlocker` and other such systems traversing `ActorSystem#group` regularly.
* Reduce number of supervisors instantiated by `ActorSystem` by consolidating them down to `Service::Root` container instances.

0.16.0 (2014-09-04)
-----
* Factor apart Celluloid::Cell (concurrent objects) from Celluloid::Actor
* Introduce Celluloid::ActorSystem as an abstraction around the backend
  actor implementation (idea borrowed from Akka)
* Celluloid::Probe system for monitoring system behavior
* Fix handling of timeouts with Celluloid::EventedMailbox (i.e. Celluloid::IO
  and Celluloid::ZMQ)
* Add timeout support to Celluloid::Condition
* Obtain actor names via Celluloid::Actor.registered_name and
  #registered_name to avoid conflicts with the built-in Ruby
  Class.name method
* Update to timers 4.0.0
* Dynamically resizable pools
* Remove use of core Ruby ThreadGroups
* Simplified CPU core detector
* Better thread names on JRuby for easier debugging
* Thread safety fixes to internal thread pool

0.15.2 (2013-10-06)
-----
* require 'celluloid/test' for at_exit-free testing

0.15.1 (2013-09-06)
-----
* Only raise on nested tasks if $CELLULOID_DEBUG is set

0.15.0 (2013-09-04)
-----
* Remove legacy support for "bang"-method based async invocation
* Generic timeout support with Celluloid#timeout
* Implement recursion detection for #inspect, avoiding infinite loop bugs
* Fix various inheritance anomalies in class attributes (e.g. mailbox_class)
* Avoid letting version.rb define an unusable Celluloid module
* Remove "Shutdown completed cleanly" message that was annoying everyone
* Subclass all Celluloid exceptions from Celluloid::Error
* Log all unhandled messages
* Celluloid::Conditions are now usable ubiquitously, not just inside actors
* Introspection support for number of threads in the Celluloid thread pool
* Use a ThreadGroup to track the threads in the Celluloid thread pool
* Reimplement signal system on top of Conditions
* Add metadata like the current method to Celluloid::StackDumps

0.14.0 (2013-05-07)
-----
* Use a Thread-subclass for Celluloid
  * Implement actor-local variables
  * Add helper methods to the class
* Move IO::Mailbox to EventedMailbox to remove dependency between
  celluloid-io and celluloid-zmq. This makes it easier to maintain
  the evented style of Mailbox.
* Install the `at_exit` handler by default
* Show backtrace for all tasks. Currently only for TaskThread
* Implement mailbox bounds where overflow is logged
* Fix Thread self-join
* Execute blocks on the sender by default
* Fix CPU counter on windows

0.13.0
-----
* API change: Require Celluloid with: require 'celluloid/autostart' to
  automatically start support actors and configure at_exit handler which
  automatically terminates all actors.
* API change: use_mailbox has been removed
* API change: finalizers must be declared with "finalizer :my_finalizer"
* Bugfix: receivers don't crash when methods are called incorrectly
* Celluloid::Condition provides ConditionVariable-like signaling
* Shutdown timeout reduced to 10 seconds
* Stack traces across inter-actor calls! Should make Celluloid backtraces
  much easier to understand
* Celluloid#call_chain_id provides UUIDs for calls across actors
* Give all thread locals a :celluloid_* prefix

0.12.4
-----
* Bugfix: Clear dead/crashed actors out of links
* Bugfix: Exclusive mode was broken
* Bugfix: Celluloid::SupervisionGroup#run was broken
* Celluloid::ClassMethods#proxy_class allows configurable proxies
* Improved error messages for Fiber-related problems
* Better object leakage detection when inspecting
* Use #public_send to dispatch Celluloid methods
* #idle_size and #busy_size for Celluloid::PoolManager

0.12.3
-----
* Bugfix: Ensure exclusive mode works correctly for per-method case
* Bugfix: Exit handlers were not being inherited correctly

0.12.2
-----
* Disable IncidentReporter by default

0.12.1
-----
* Fix bug in unsetting of exclusive mode
* New incident report system for providing better debugging reports
* Revert BasicObject proxies for now... they are causing problems
* String inspect that reveals bare object leaks
* Fix bug reporting proper task statuses
* Initial thread dumper support
* Remove Celluloid#alive? as it cannot be called in any manner that will ever
  return anything but true, rendering it useless

0.12.0
-----
* Alternative async syntax: actor.async.method in lieu of actor.method!
  Original syntax still available but will be removed in Celluloid 1.0
* Alternative future syntax: actor.future.method in lieu of future(:method)
* All methods in the Celluloid module are now available on its singleton
* The #join and #kill methods are no longer available on the actor proxy.
  Please use Celluloid::Actor.join(actor) and .kill(actor) instead.
* Celluloid::Future#ready? can be used to query for future readiness
* Celluloid::Group constant removed. Please use Celluloid::SupervisionGroup
* #monitor, #unmonitor, and #monitoring? provide unidirectional linking
* Linking is now performed via a SystemEvent
* SystemEvents are no longer exceptions. Boo exceptions as flow control!
* Celluloid::Mailbox#system_event eliminated and replaced with Mailbox#<<
  SystemEvents are now automatically high priority
* The task_class class method can be used to override the class used for
  tasks, allowing different task implementations to be configured on an
  actor-by-actor-basis
* Celluloid::TaskThread provides tasks backed by Threads instead of Fibers
* ActorProxy is now a BasicObject
* A bug prevented Celluloid subclasses from retaining custom mailboxes
  defined by use_mailbox. This is now fixed.
* `exclusive` class method without arguments makes the whole actor exclusive

0.11.1
-----
* 'exclusive' class method marks methods as always exclusive and runs them
  outside of a Fiber (useful if you need more stack than Fibers provide)
* Celluloid::PoolManager returns its own class when #class is called, instead
  of proxying to a cell/actor in the pool.
* #receive now handles SystemEvents internally
* Celluloid::Timers extracted into the timers gem, which Celluloid now
  uses for its own timers

0.11.0
-----
* Celluloid::Application constant permanently removed
* Celluloid::Pool removed in favor of Celluloid.pool
* Celluloid::Group renamed to Celluloid::SupervisionGroup, old name is
  still available and has not been deprecated
* Celluloid::ThreadPool renamed to Celluloid::InternalPool to emphasize its
  internalness
* Support for asynchronously calling private methods inside actors
* Future is now an instance method on all actors
* Async call exception logs now contain the failed method
* MyActor#async makes async calls for those who dislike the predicate syntax
* abort can now accept a string instead of an exception object and will raise
  RuntimeError in the caller's context

0.10.0
-----
* Celluloid::Actor.current is now the de facto way to obtain the current actor
* #terminate now uses system messages, making termination take priority over
  other pending methods
* #terminate! provides asynchronous termination

0.9.1
-----
* Recurring timers with Celluloid#every(n) { ... }
* Obtain UUIDs with Celluloid.uuid
* Obtain the number of CPU cores available with Celluloid.cores
* Celluloid::Pool defaults to one actor per CPU core max by default

0.9.0
-----
* Celluloid::Pool supervises pools of actors
* Graceful shutdown which calls #terminate on all actors
* Celluloid::Actor.all returns all running actors
* Celluloid#exclusive runs a high priority block which prevents other methods
  from executing
* Celluloid.exception_handler { |ex| ... } defines a callback for notifying
  exceptions (for use with Airbrake, exception_notifier, etc.)

0.8.0
-----
* Celluloid::Application is now Celluloid::Group
* Futures no longer use a thread unless created with a block
* No more future thread-leaks! Future threads auto-terminate now
* Rename Celluloid#async to Celluloid#defer
* Celluloid#tasks now returns an array of tasks with a #status attribute
* Reduce coupling between Celluloid and DCell. Breaks compatibility with
  earlier versions of DCell.
* Celluloid::FSMs are no longer actors themselves
* Benchmarks using benchmark_suite

0.7.2
-----
* Workaround fiber problems on JRuby 1.6.5.1 in addition to 1.6.5
* Fix class displayed when inspecting dead actors

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

[@ioquatix]: https://github.com/ioquatix
[@TiagoCardoso1983]: https://github.com/TiagoCardoso1983
