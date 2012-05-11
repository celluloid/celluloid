require 'spec_helper'

describe Celluloid::IO::TCPSocket do
  let(:payload) { 'ohai' }

  context "inside Celluloid::IO" do
    it "connects to TCP servers" do
      server = ::TCPServer.new example_addr, example_port
      thread = Thread.new { server.accept }
      socket = within_io_actor { Celluloid::IO::TCPSocket.new example_addr, example_port }
      peer = thread.value

      peer << payload
      within_io_actor { socket.read(payload.size) }.should eq payload

      server.close
      socket.close
      peer.close
    end

    it "should be evented" do
      with_connected_sockets do |subject|
        within_io_actor { subject.evented? }.should be_true
      end
    end

    it "read complete payload when nil size is given to #read" do
        with_connected_sockets do |subject, peer|
        peer << payload
        within_io_actor { subject.read(nil) }.should eq payload
      end
    end

    it "read complete payload when no size is given to #read" do
        with_connected_sockets do |subject, peer|
        peer << payload
        within_io_actor { subject.read }.should eq payload
      end
    end

    it "reads data" do
      with_connected_sockets do |subject, peer|
        peer << payload
        within_io_actor { subject.read(payload.size) }.should eq payload
      end
    end

    it "reads partial data" do
      with_connected_sockets do |subject, peer|
        peer << payload * 2
        within_io_actor { subject.readpartial(payload.size) }.should eq payload
      end
    end

    it "writes data" do
      with_connected_sockets do |subject, peer|
        within_io_actor { subject << payload }
        peer.read(payload.size).should eq payload
      end
    end
  end

  context "elsewhere in Ruby" do
    it "connects to TCP servers" do
      server = ::TCPServer.new example_addr, example_port
      thread = Thread.new { server.accept }
      socket = Celluloid::IO::TCPSocket.new example_addr, example_port
      peer = thread.value

      peer << payload
      socket.read(payload.size).should eq payload

      server.close
      socket.close
      peer.close
    end

    it "should be blocking" do
      with_connected_sockets do |subject|
        subject.should_not be_evented
      end
    end

    it "reads data" do
      with_connected_sockets do |subject, peer|
        peer << payload
        subject.read(payload.size).should eq payload
      end
    end

    it "reads partial data" do
      with_connected_sockets do |subject, peer|
        peer << payload * 2
        subject.readpartial(payload.size).should eq payload
      end
    end

    it "writes data" do
      with_connected_sockets do |subject, peer|
        subject << payload
        peer.read(payload.size).should eq payload
      end
    end
  end
end
