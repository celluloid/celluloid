require 'spec_helper'

describe Celluloid::IO::TCPServer do
  describe "#accept" do
    let(:payload) { 'ohai' }

    it "can be initialized without a host" do
      expect{ server = Celluloid::IO::TCPServer.new(2000); server.close }.to_not raise_error
    end

    context "inside Celluloid::IO" do
      it "should be evented" do
        with_tcp_server do |subject|
          within_io_actor { Celluloid::IO.evented? }.should be_true
        end
      end

      it "accepts a connection and returns a Celluloid::IO::TCPSocket" do
        with_tcp_server do |subject|
          thread = Thread.new { TCPSocket.new(example_addr, example_port) }
          peer = within_io_actor { subject.accept }
          peer.should be_a Celluloid::IO::TCPSocket

          client = thread.value
          client.write payload
          peer.read(payload.size).should eq payload
        end
      end

      context "outside Celluloid::IO" do
        it "should be blocking" do
          with_tcp_server do |subject|
            Celluloid::IO.should_not be_evented
          end
        end

        it "accepts a connection and returns a Celluloid::IO::TCPSocket" do
          with_tcp_server do |subject|
            thread = Thread.new { TCPSocket.new(example_addr, example_port) }
            peer   = subject.accept
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
