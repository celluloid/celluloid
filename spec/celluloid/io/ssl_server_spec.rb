require 'spec_helper'

describe Celluloid::IO::SSLServer do
  let(:client_cert) { OpenSSL::X509::Certificate.new fixture_dir.join("client.crt").read }
  let(:client_key)  { OpenSSL::PKey::RSA.new fixture_dir.join("client.key").read }
  let(:client_context) do
    OpenSSL::SSL::SSLContext.new.tap do |context|
      context.cert = client_cert
      context.key  = client_key
    end
  end

  let(:server_cert) { OpenSSL::X509::Certificate.new fixture_dir.join("server.crt").read }
  let(:server_key)  { OpenSSL::PKey::RSA.new fixture_dir.join("server.key").read }
  let(:server_context) do
    OpenSSL::SSL::SSLContext.new.tap do |context|
      context.cert = server_cert
      context.key  = server_key
    end
  end

  describe "#accept" do
    let(:payload) { 'ohai' }

    context "inside Celluloid::IO" do
      it "should be evented" do
        with_ssl_server do |subject|
          within_io_actor { Celluloid::IO.evented? }.should be_true
        end
      end

      it "accepts a connection and returns a Celluloid::IO::SSLSocket" do
        with_ssl_server do |subject|
          thread = Thread.new do
            raw = TCPSocket.new(example_addr, example_ssl_port)
            OpenSSL::SSL::SSLSocket.new(raw, client_context).connect
          end
          peer = within_io_actor { subject.accept }
          peer.should be_a Celluloid::IO::SSLSocket

          client = thread.value
          client.write payload
          peer.read(payload.size).should eq payload
        end
      end
    end

    context "outside Celluloid::IO" do
      it "should be blocking" do
        with_ssl_server do |subject|
          Celluloid::IO.should_not be_evented
        end
      end

      it "accepts a connection and returns a Celluloid::IO::SSLSocket" do
        with_ssl_server do |subject|
          thread = Thread.new do
            raw = TCPSocket.new(example_addr, example_ssl_port)
            OpenSSL::SSL::SSLSocket.new(raw, client_context).connect
          end
          peer = subject.accept
          peer.should be_a Celluloid::IO::SSLSocket

          client = thread.value
          client.write payload
          peer.read(payload.size).should eq payload
        end
      end
    end
  end

  describe "#initialize" do
    it "should auto-wrap a raw ::TCPServer" do
      raw_server = ::TCPServer.new(example_addr, example_ssl_port)
      with_ssl_server(raw_server) do |ssl_server|
        ssl_server.tcp_server.class.should == Celluloid::IO::TCPServer
      end
    end
  end

  def with_ssl_server(raw_server = nil)
    raw_server ||= Celluloid::IO::TCPServer.new(example_addr, example_ssl_port)
    server = Celluloid::IO::SSLServer.new(raw_server, server_context)
    begin
      yield server
    ensure
      server.close
    end
  end
end

