require 'rubygems'
require 'bundler/setup'
require 'celluloid/io'
require 'celluloid/rspec'

logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
Celluloid.logger = Logger.new(logfile)

class ExampleActor
  include Celluloid::IO

  def wrap
    yield
  end
end

EXAMPLE_PORT = 10000 + rand(10000)

def example_addr; '127.0.0.1'; end
def example_port; EXAMPLE_PORT; end
def example_sock; '/tmp/cell_sock'; end

def within_io_actor(&block)
  actor = ExampleActor.new
  actor.wrap(&block)
ensure
  actor.terminate if actor.alive?
end

def with_tcp_server
  server = Celluloid::IO::TCPServer.new(example_addr, example_port)
  begin
    yield server
  ensure
    server.close
  end
end

def with_unix_server
  server = Celluloid::IO::UNIXServer.open(example_sock)
  begin
    yield server
  ensure
    server.close
    File.delete(example_sock)
  end                  
end

def with_connected_sockets
  with_tcp_server do |server|
    # FIXME: client isn't actually a Celluloid::IO::TCPSocket yet
    client = ::TCPSocket.new(example_addr, example_port)
    peer = server.accept

    begin
      yield peer, client
    ensure
      begin
        client.close
        peer.close
      rescue
      end
    end
  end
end

def with_connected_unix_sockets
  with_unix_server do |server|
    client = Celluloid::IO::UNIXSocket.new(example_sock)
    peer = server.accept

    begin
      yield peer, client
    ensure
      begin
        client.close
        peer.close
      rescue
      end
    end
  end
end
