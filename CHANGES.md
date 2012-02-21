HEAD
----
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
