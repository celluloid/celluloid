require 'spec_helper'

describe Celluloid::IO::UNIXSocket do
  before do
    pending "JRuby support" if defined?(JRUBY_VERSION)
  end

  let(:payload) { 'ohai' }

  context "inside Celluloid::IO" do
    it "connects to UNIX servers" do
      server = ::UNIXServer.open example_unix_sock
      thread = Thread.new { server.accept }
      socket = within_io_actor { Celluloid::IO::UNIXSocket.open example_unix_sock }
      peer = thread.value

      peer << payload
      within_io_actor { socket.read(payload.size) }.should eq payload

      server.close
      socket.close
      peer.close
      File.delete(example_unix_sock)
    end

    it "should be evented" do
      with_connected_unix_sockets do |subject|
        within_io_actor { Celluloid::IO.evented? }.should be_true
      end
    end

    it "read complete payload when nil size is given to #read" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        within_io_actor { subject.read(nil) }.should eq payload
      end
    end

    it "read complete payload when no size is given to #read" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        within_io_actor { subject.read }.should eq payload
      end
    end

    it "reads data" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        within_io_actor { subject.read(payload.size) }.should eq payload
      end
    end

    it "reads data in binary encoding" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        within_io_actor { subject.read(payload.size).encoding }.should eq Encoding::BINARY
      end
    end

    it "reads partial data" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload * 2
        within_io_actor { subject.readpartial(payload.size) }.should eq payload
      end
    end

    it "reads partial data in binary encoding" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload * 2
        within_io_actor { subject.readpartial(payload.size).encoding }.should eq Encoding::BINARY
      end
    end

    it "writes data" do
      with_connected_unix_sockets do |subject, peer|
        within_io_actor { subject << payload }
        peer.read(payload.size).should eq payload
      end
    end

    it "raises Errno::ENOENT when the connection is refused" do
      expect {
        within_io_actor { Celluloid::IO::UNIXSocket.open(example_unix_sock) }
      }.to raise_error(Errno::ENOENT)
    end

    it "raises EOFError when partial reading from a closed socket" do
      with_connected_unix_sockets do |subject, peer|
        peer.close
        expect {
          within_io_actor { subject.readpartial(payload.size) }
        }.to raise_error(EOFError)
      end
    end
  end

  context "outside Celluloid::IO" do
    it "connects to UNIX servers" do
      server = ::UNIXServer.new example_unix_sock
      thread = Thread.new { server.accept }
      socket = Celluloid::IO::UNIXSocket.open example_unix_sock
      peer = thread.value

      peer << payload
      socket.read(payload.size).should eq payload

      server.close
      socket.close
      peer.close
      File.delete example_unix_sock
    end

    it "should be blocking" do
      with_connected_unix_sockets do |subject|
        Celluloid::IO.should_not be_evented
      end
    end

    it "reads data" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload
        subject.read(payload.size).should eq payload
      end
    end

    it "reads partial data" do
      with_connected_unix_sockets do |subject, peer|
        peer << payload * 2
        subject.readpartial(payload.size).should eq payload
      end
    end

    it "writes data" do
      with_connected_unix_sockets do |subject, peer|
        subject << payload
        peer.read(payload.size).should eq payload
      end
    end
  end
end
