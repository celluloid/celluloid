require 'spec_helper'

describe Celluloid::TCPServer do
  HOST = "127.0.0.1"
  PORT = 10036

  class MyServer < Celluloid::TCPServer
    def initialize(host, port)
      super
      @connections = {}
    end

    def on_connect(connection)
      @connections[connection] = true
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
    end.to change(server, :connection_count).by(1)
  end

  it "refuses to register non-Actors" do
    expect do
      Celluloid::Actor[:impostor] = Object.new
    end.to raise_error(ArgumentError)
  end
end
