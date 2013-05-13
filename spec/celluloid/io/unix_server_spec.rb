require 'spec_helper'

describe Celluloid::IO::UNIXServer do
  describe "#accept" do
    before do
      pending "JRuby support" if defined?(JRUBY_VERSION)
    end

    let(:payload) { 'ohai' }

    context "inside Celluloid::IO" do
      it "should be evented" do
        with_unix_server do |subject|
          within_io_actor { Celluloid::IO.evented? }.should be_true
        end
      end

      it "accepts a connection and returns a Celluloid::IO::UNIXSocket" do
        with_unix_server do |subject|
          thread = Thread.new { UNIXSocket.new(example_unix_sock) }
          peer = within_io_actor { subject.accept }
          peer.should be_a Celluloid::IO::UNIXSocket

          client = thread.value
          client.write payload
          peer.read(payload.size).should eq payload
        end
      end

      it "raises if server already up" do
        with_unix_server do |subject|
          within_io_actor do
            expect {
              Celluloid::IO::UNIXServer.open(example_unix_sock)
            }.to raise_error(Errno::EADDRINUSE)
          end
        end
      end

      context "outside Celluloid::IO" do
        it "should be blocking" do
          with_unix_server do |subject|
            Celluloid::IO.should_not be_evented
          end
        end

        it "accepts a connection and returns a Celluloid::IO::UNIXSocket" do
          with_unix_server do |subject|
            thread = Thread.new { UNIXSocket.new(example_unix_sock) }
            peer   = subject.accept
            peer.should be_a Celluloid::IO::UNIXSocket

            client = thread.value
            client.write payload
            peer.read(payload.size).should eq payload
          end
        end

        it "raises if server already up" do
          with_unix_server do |subject|
            expect {
              Celluloid::IO::UNIXServer.open(example_unix_sock)
            }.to raise_error(Errno::EADDRINUSE)
          end
        end

      end
    end
  end
end
