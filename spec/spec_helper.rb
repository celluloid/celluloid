require 'rubygems'
require 'bundler/setup'
require 'celluloid/io'
require 'celluloid/rspec'

class ExampleActor
  include Celluloid::IO

  def wrap
    yield
  end
end

EXAMPLE_PORT = 10000 + rand(10000)

def example_addr; '127.0.0.1'; end
def example_port; EXAMPLE_PORT; end

def within_io_actor(&block)
  actor = ExampleActor.new
  actor.wrap(&block)
ensure
  actor.terminate
end

def with_tcp_server
  server = Celluloid::IO::TCPServer.new(example_addr, example_port)
  yield server
ensure
  server.close
end

def with_connected_sockets
  with_tcp_server do |server|
    client = TCPSocket.new(example_addr, example_port)
    peer = server.accept

    begin
      yield client,
    ensure
      client.close
      peer.close
    end
  end
end
