require 'spec_helper'
require 'openssl'

describe Celluloid::IO::SSLSocket do
  let(:request)  { 'ping' }
  let(:response) { 'pong' }

  let(:client_cert) { OpenSSL::X509::Certificate.new fixture_dir.join("client.crt").read }
  let(:client_key)  { OpenSSL::PKey::RSA.new fixture_dir.join("client.key").read }
  let(:client_context) do
    OpenSSL::SSL::SSLContext.new.tap do |context|
      context.cert = client_cert
      context.key  = client_key
    end
  end

  let(:client)     { TCPSocket.new example_addr, example_ssl_port }
  let(:ssl_client) { Celluloid::IO::SSLSocket.new client, client_context }

  let(:server_cert) { OpenSSL::X509::Certificate.new fixture_dir.join("server.crt").read }
  let(:server_key)  { OpenSSL::PKey::RSA.new fixture_dir.join("server.key").read }
  let(:server_context) do
    OpenSSL::SSL::SSLContext.new.tap do |context|
      context.cert = server_cert
      context.key  = server_key
    end
  end

  let(:server)     { TCPServer.new example_addr, example_ssl_port }
  let(:ssl_server) { OpenSSL::SSL::SSLServer.new server, server_context }
  let(:server_thread) do
    Thread.new { ssl_server.accept }.tap do |thread|
      Thread.pass while thread.status && thread.status != "sleep"
    end
  end

  context "inside Celluloid::IO" do
    it "connects to SSL servers over TCP" do
      thread = server_thread
      ssl_peer = nil
      ssl_client.connect

      begin
        within_io_actor do
          ssl_peer = thread.value
          ssl_peer << request
          ssl_client.read(request.size).should == request

          ssl_client << response
          ssl_peer.read(response.size).should == response
        end
      ensure
        ssl_server.close
        ssl_client.close
        ssl_peer.close
      end
    end
  end

  context "outside Celluloid::IO" do
    it "connects to SSL servers over TCP" do
      thread = server_thread
      ssl_client.connect

      begin
        ssl_peer = thread.value
        ssl_peer << request
        ssl_client.read(request.size).should == request

        ssl_client << response
        ssl_peer.read(response.size).should == response
      ensure
        ssl_server.close
        ssl_client.close
        ssl_peer.close
      end
    end
  end

  it "knows its cert" do
    thread = server_thread
    ssl_client.connect

    begin
      ssl_peer = thread.value
      ssl_client.cert.should eq client_cert
    ensure
      ssl_server.close
      ssl_client.close
      ssl_peer.close
    end
  end
end
