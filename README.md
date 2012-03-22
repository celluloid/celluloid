![Celluloid::ZMQ](https://github.com/celluloid/celluloid-zmq/raw/master/logo.png)
=================
[![Build Status](https://secure.travis-ci.org/celluloid/celluloid-zmq.png?branch=master)](http://travis-ci.org/celluloid/celluloid-zmq)

Celluloid::ZMQ provides Celluloid actors that can interact with 0MQ sockets.
Underneath, it's built on the [ffi-rzmq][ffi-rzmq] library.

[ffi-rzmq]: https://github.com/chuckremes/ffi-rzmq

It provides different `Celluloid::ZMQ::Socket` classes which can be initialized
then sent `bind` or `connect`. Once bound or connected, the socket can
`read` or `send` depending on whether it's readable or writable.

## Supported Platforms

Celluloid::IO requires Ruby 1.9 support on all Ruby VMs.

Supported VMs are Ruby 1.9.3, JRuby 1.6, and Rubinius 2.0.

To use JRuby in 1.9 mode, you'll need to pass the "--1.9" command line option
to the JRuby executable, or set the "JRUBY_OPTS=--1.9" environment variable.

## 0MQ Socket Types

The following 0MQ socket types are supported (see [sockets.rb][socketsrb] for more info)

[socketsrb]: https://github.com/celluloid/celluloid-zmq/blob/master/lib/celluloid/zmq/sockets.rb

* ReqSocket / RepSocket
* PushSocket / PullSocket
* PubSocket / SubSocket

## Usage

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

Copyright (c) 2012 Tony Arcieri. See LICENSE.txt for further details.
