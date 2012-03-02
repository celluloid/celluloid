Celluloid::ZMQ
==============

This gem uses the ffi-rzmq library to provide Celluloid actors that can
interact with 0MQ sockets.

It provides different `Celluloid::ZMQ::Socket`s which can be initialized
then sent `bind` or `connect`. Once bound or connected, the socket can
`read` or `send` depending on whether it's readable or writable.

Example Usage:

```ruby
require 'celluloid/zmq'

Celluloid::ZMQ.init

class Server
  include Celluloid::ZMQ

  def initialize(address)
    @socket = PullSocket.new

    begin
      @socket.bind(address)
    rescue IOError
      @socket.close
      raise
    end
  end

  def run
    while true; handle_message! @socket.read; end
  end

  def handle_message(message)
    puts "got message: #{message}"
  end
end

class Client
  include Celluloid::ZMQ

  def initialize(address)
    @socket = PushSocket.new

    begin
      @socket.connect(address)
    rescue IOError
      @socket.close
      raise
    end
  end

  def write(message)
    @socket.send(message)

    nil
  end
end

addr = 'tcp://127.0.0.1:3435'

server = Server.new(addr)
client = Client.new(addr)

server.run!
client.write('hi')
```

Copyright
---------

Copyright (c) 2011 Tony Arcieri. See LICENSE.txt for further details.
