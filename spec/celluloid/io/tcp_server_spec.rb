require 'spec_helper'

describe Celluloid::IO::TCPServer do
  describe "#accept" do
    let(:payload) { 'ohai' }

    context "inside Celluloid::IO" do
      it "should be evented" do
        with_tcp_server do |server|
          within_io_actor { server.evented? }.should be_true
        end
      end

      it "accepts a connection and returns a Celluloid::IO::TCPSocket" do
        with_tcp_server do |server|
          thread = Thread.new { TCPSocket.new(example_addr, example_port) }
          peer = within_io_actor { server.accept }
          peer.should be_a Celluloid::IO::TCPSocket

          client = thread.value
          client.write payload
          peer.read(payload.size).should eq payload
        end
      end

      context "elsewhere in Ruby" do
        it "accepts a connection and returns a Celluloid::IO::TCPSocket" do
          with_tcp_server do |server|
            thread = Thread.new { TCPSocket.new(example_addr, example_port) }
            peer   = server.accept
            peer.should be_a Celluloid::IO::TCPSocket

            client = thread.value
            client.write payload
            peer.read(payload.size).should eq payload
          end
        end
      end
    end
  end
end
