require 'rubygems'
require 'bundler/setup'
require 'celluloid/io'
require 'celluloid/rspec'
require 'coveralls'
Coveralls.wear!

logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
logfile.sync = true

logger = Celluloid.logger = Logger.new(logfile)

Celluloid.shutdown_timeout = 1

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before do
    Celluloid.logger = logger
    Celluloid.shutdown

    Celluloid.boot

    FileUtils.rm("/tmp/cell_sock") if File.exist?("/tmp/cell_sock")
  end
end

class ExampleActor
  include Celluloid::IO
  execute_block_on_receiver :wrap

  def wrap
    yield
  end
end

EXAMPLE_PORT = 12345

def example_addr; '127.0.0.1'; end
def example_port; EXAMPLE_PORT; end
def example_unix_sock; '/tmp/cell_sock'; end
def example_ssl_port; EXAMPLE_PORT + 1; end

def fixture_dir; Pathname.new File.expand_path("../fixtures", __FILE__); end

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
  server = Celluloid::IO::UNIXServer.open(example_unix_sock)
  begin
    yield server
  ensure
    server.close
    File.delete(example_unix_sock)
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
    client = Celluloid::IO::UNIXSocket.new(example_unix_sock)
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
