0.16.0 (2014-09-04)
-------------------
* Support for setting socket options
* More specs

0.15.0 (2013-09-04)
-------------------
* Tracking release for Celluloid 0.15

0.14.0 (2013-05-07)
-------------------
* Add pubsub example
* Add identity support to Sockets
* Depend on EventedMailbox from core instead of celluloid-io
* Remove overhead for IO waiting by calling directly to the reactor

0.13.0
------
* Feature: Support for DealerSocket and RouterSocket
* Support for the #more_parts? method on sockets
* Celluloid 0.13 compatibility fixes

0.12.0
------
* Tracking release for Celluloid 0.12.0

0.10.0
------
* Factor celluloid-zmq into its own gem
* #linger= support

0.9.0
-----
* New 0MQ APIs which wrap ffi-rzmq's
* Terminate the 0MQ context at shutdown
* Use Celluloid::IO 0.9.0's reactor injection support so we no longer have to
  subclass Celluloid::IO::Mailbox

0.8.0
-----
* Update to match internals of celluloid-io

0.7.0
-----
* Use celluloid-io gem
* Match versions with Celluloid

0.0.4
-----
* Fix bugs in 0MQ polling (timeouts were being processed 1000x too fast)

0.0.3
-----
* Fix botched dependencies (celluloid-zmq does not depend on redis)

0.0.2
-----
* Pure blocking 0MQ reactor using a ZMQ::PAIR socket as the waker

0.0.1
-----
* Initial release
