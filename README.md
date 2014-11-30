Welcome to Celluloid
====================

> "I thought of objects being like biological cells and/or individual
> computers on a network, only able to communicate with messages"
> _--Alan Kay, creator of Smalltalk, on the meaning of "object oriented programming"_

Celluloid is a concurrent object oriented programming framework for Ruby which lets
you build multithreaded programs out of concurrent objects just as easily as you build
sequential programs out of regular objects.

This Repository
---------------

This repository contains the following subcomponents of Celluloid:

* [celluloid]: the core library of the Celluloid concurrency framework
* [celluloid-io]: evented IO support for Celluloid
* [celluloid-zmq]: evented sockets for the [0MQ] framework

[celluloid]: https://github.com/celluloid/celluloid/tree/master/celluloid/
[celluloid-io]: https://github.com/celluloid/celluloid/tree/master/celluloid-io/
[celluloid-zmq]: https://github.com/celluloid/celluloid/tree/master/celluloid-zmq/

Additional Repositories
-----------------------

The following other repositories either integrate with or augment
Celluloid's core functionality:

* [DCell]: distributed Celluloid built on top of [Celluloid::ZMQ]
* [Reel]: a Celluloid::IO-powered web server
* [http.rb]: an fast, easy-to-use HTTP library with [Celluloid::IO] support
* [timers]: fast, pure Ruby timers, providing Celluloid's timing subsystem

[DCell]: https://github.com/celluloid/dcell/
[Reel]: https://github.com/celluloid/reel/
[http.rb]: https://github.com/tarcieri/http.rb/
[timers]: https://github.com/celluloid/timers/
