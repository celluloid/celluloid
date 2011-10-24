require 'spec_helper'

describe Celluloid::TCPServer, pending: !!ENV['CI'] do
  HOST = "127.0.0.1"
  PORT = 10036

  class MyServer < Celluloid::TCPServer
    def initialize(host, port)
      super
      @connections = {}
    end

    def on_connect(connection)
      @connection_received = true
      signal :connection_received

      @connections[connection] = true
    end

    def wait_for_connection
      unless @connection_received
        wait :connection_received
      end

      @connection_received = false
      true
    end

    def connection_count
      @connections.size
    end
  end

  it "accepts connections" do
    server = MyServer.new HOST, PORT

    client = nil
    expect do
      client = TCPSocket.open HOST, PORT
      server.wait_for_connection
    end.to change(server, :connection_count).by(1)

    client.close
    server.terminate
  end
end
