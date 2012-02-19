require 'spec_helper'

describe Celluloid::IO::TCPSocket do
  let(:payload) { 'ohai' }

  context "inside Celluloid::IO" do
    it "should be evented" do
      with_connected_sockets do |subject|
        within_io_actor { subject.evented? }.should be_true
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
