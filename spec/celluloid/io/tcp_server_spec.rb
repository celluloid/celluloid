require 'spec_helper'

describe Celluloid::IO::TCPServer do
  describe "#accept" do
    context "inside Celluloid::IO" do
      it "accepts a connection and returns a Celluloid::IO::TCPSocket" do
        with_tcp_server do |server|
          thread = Thread.new { TCPSocket.new('127.0.0.1', example_port) }
          peer = within_io_actor { server.accept }
          client = thread.value

          payload = 'ohai'
          client.write payload
          peer.read(payload.size).should eq payload
        end
      end
    end
  end
end
