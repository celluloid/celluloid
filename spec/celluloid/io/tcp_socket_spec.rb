require 'spec_helper'

describe Celluloid::IO::TCPSocket do
  let(:payload) { 'ohai' }

  describe "#read" do
    context "inside Celluloid::IO" do
      it "reads data" do
        # FIXME: client isn't actually a Celluloid::IO::TCPSocket yet
        with_connected_sockets do |subject, peer|
          peer << payload
          within_io_actor { subject.read(payload.size) }.should eq payload
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
    end
  end

  describe "#write" do
    context "inside Celluloid::IO" do
      it "writes data" do
        with_connected_sockets do |subject, peer|
          within_io_actor { subject << payload }
          peer.read(payload.size).should eq payload
        end
      end
    end

    context "elsewhere in Ruby" do
      it "writes data" do
        with_connected_sockets do |subject, peer|
          subject << payload
          peer.read(payload.size).should eq payload
        end
      end
    end
  end
end
