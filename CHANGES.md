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
