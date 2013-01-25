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

  let(:celluloid_server) { Celluloid::IO::TCPServer.new example_addr, example_ssl_port }
  let(:raw_server_thread) do
    Thread.new { celluloid_server.accept }.tap do |thread|
      Thread.pass while thread.status && thread.status != "sleep"
    end
  end

  context "inside Celluloid::IO" do
    it "connects to SSL servers over TCP" do
      with_ssl_sockets do |ssl_client, ssl_peer|
        within_io_actor do
          ssl_peer << request
          ssl_client.read(request.size).should == request

          ssl_client << response
          ssl_peer.read(response.size).should == response
        end
      end
    end

    it "starts SSL on a connected TCP socket" do
      with_raw_sockets do |client, peer|
        within_io_actor do
          peer << request
          client.read(request.size).should == request

          client << response
          peer.read(response.size).should == response

          # now that we've written bytes, upgrade to SSL
          client_thread = Thread.new { OpenSSL::SSL::SSLSocket.new(client).connect }
          ssl_peer = Celluloid::IO::SSLSocket.new peer, server_context
          ssl_peer.should == ssl_peer.accept
          ssl_client = client_thread.value

          ssl_peer << request
          ssl_client.read(request.size).should == request

          ssl_client << response
          ssl_peer.read(response.size).should == response
        end
      end
    end
  end

  context "outside Celluloid::IO" do
    it "connects to SSL servers over TCP" do
      with_ssl_sockets do |ssl_client, ssl_peer|
        ssl_peer << request
        ssl_client.read(request.size).should == request

        ssl_client << response
        ssl_peer.read(response.size).should == response
      end
    end

    it "starts SSL on a connected TCP socket" do
      with_raw_sockets do |client, peer|
        peer << request
        client.read(request.size).should == request

        client << response
        peer.read(response.size).should == response

        # now that we've written bytes, upgrade to SSL
        client_thread = Thread.new { OpenSSL::SSL::SSLSocket.new(client).connect }
        ssl_peer = Celluloid::IO::SSLSocket.new peer, server_context
        ssl_peer.should == ssl_peer.accept
        ssl_client = client_thread.value

        ssl_peer << request
        ssl_client.read(request.size).should == request

        ssl_client << response
        ssl_peer.read(response.size).should == response
      end
    end
  end

  it "knows its cert" do
    # FIXME: seems bad? o_O
    pending "wtf is wrong with this on JRuby" if defined? JRUBY_VERSION
    with_ssl_sockets do |ssl_client|
      ssl_client.cert.to_der.should == client_cert.to_der
    end
  end

  it "knows its peer_cert" do
    with_ssl_sockets do |ssl_client|
      ssl_client.peer_cert.to_der.should == ssl_client.to_io.peer_cert.to_der
    end
  end

  it "knows its peer_cert_chain" do
    with_ssl_sockets do |ssl_client|
      ssl_client.peer_cert_chain.zip(ssl_client.to_io.peer_cert_chain).map do |c1, c2|
        c1.to_der == c2.to_der
      end.should be_all
    end
  end

  it "knows its cipher" do
    with_ssl_sockets do |ssl_client|
      ssl_client.cipher.should == ssl_client.to_io.cipher
    end
  end

  it "knows its client_ca" do
    # jruby-openssl does not implement this method
    pending "jruby-openssl support" if defined? JRUBY_VERSION

    with_ssl_sockets do |ssl_client|
      ssl_client.client_ca.should == ssl_client.to_io.client_ca
    end
  end

  it "verifies peer certificates" do
    # FIXME: JRuby seems to be giving the wrong result here o_O
    pending "jruby-openssl support" if defined? JRUBY_VERSION

    with_ssl_sockets do |ssl_client, ssl_peer|
      ssl_client.verify_result.should == OpenSSL::X509::V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT
    end
  end

  def with_ssl_sockets
    thread = server_thread
    ssl_client.connect

    begin
      ssl_peer = thread.value
      yield ssl_client, ssl_peer
    ensure
      ssl_server.close
      ssl_client.close
      ssl_peer.close
    end
  end

  def with_raw_sockets
    server_thread = raw_server_thread
    raw_client = client

    begin
      raw_peer = server_thread.value
      yield raw_client, raw_peer
    ensure
      celluloid_server.close
      raw_client.close
      raw_peer.close
    end
  end
end
