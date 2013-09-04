0.15.0 (2013-09-04)
-------------------
* Improved DNS resolver with less NIH and more Ruby stdlib goodness
* Better match Ruby stdlib TCPServer API
* Add missing #send and #recv on Celluloid::IO::TCPSocket
* Add missing #setsockopt method on Celluloid::IO::TCPServer
* Add missing #peeraddr method on Celluloid::IO::SSLSocket

0.14.0 (2013-05-07)
-------------------
* Add `close_read`/`close_write` delegates for rack-hijack support
* Depend on EventedMailbox from core

0.13.1
------
* Remove overhead for `wait_readable`/`wait_writable`

0.13.0
------
* Support for many, many more IO methods, particularly line-oriented
  methods like #gets, #readline, and #readlines
* Initial SSL support via Celluloid::IO::SSLSocket and
  Celluloid::IO::SSLServer
* Concurrent writes between tasks of the same actor are now coordinated
  using Celluloid::Conditions instead of signals
* Celluloid 0.13 compatibility fixes

0.12.0
------
* Tracking release for Celluloid 0.12.0

0.11.0
------
* "Unofficial" SSL support (via nio4r 0.4.0)

0.10.0
------
* Read/write operations are now atomic across tasks
* True non-blocking connect support
* Non-blocking DNS resolution support

0.9.0
-----
* TCPServer, TCPSocket, and UDPSocket classes in Celluloid::IO namespace
  with both evented and blocking I/O support
* Celluloid::IO::Mailbox.new now takes a single parameter to specify an
  alternative reactor (e.g. Celluloid::ZMQ::Reactor)

0.8.0
-----
* Switch to nio4r-based reactor
* Compatibility with Celluloid 0.8.0 API changes

0.7.0
-----
* Initial release forked from Celluloid
