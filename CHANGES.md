0.13.0.pre
----------
* Initial SSL support via Celluloid::IO::SSLSocket and
  Celluloid::IO::SSLServer
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
