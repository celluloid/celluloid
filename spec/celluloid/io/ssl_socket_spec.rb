require 'spec_helper'
require 'openssl'

describe Celluloid::IO::SSLSocket do
  let(:request)  { 'ping' }
  let(:response) { 'pong' }
  let(:server_cert) { File.read File.expand_path}

  context "inside Celluloid::IO" do
    it "connects to SSL servers over TCP" do
      server = TCPServer.new example_addr, example_ssl_port
      server_context = OpenSSL::SSL::SSLContext.new
      server_context.cert = OpenSSL::X509::Certificate.new fixture_dir.join("server.crt").read
      server_context.key  = OpenSSL::PKey::RSA.new fixture_dir.join("server.key").read
      ssl_server = OpenSSL::SSL::SSLServer.new server, server_context

      thread = Thread.new { ssl_server.accept }

      client = TCPSocket.new example_addr, example_ssl_port
      client_context = OpenSSL::SSL::SSLContext.new
      client_context.cert = OpenSSL::X509::Certificate.new fixture_dir.join("client.crt").read
      client_context.key  = OpenSSL::PKey::RSA.new fixture_dir.join("client.key").read
      ssl_socket = OpenSSL::SSL::SSLSocket.new client, client_context

      ssl_socket.connect
      ssl_peer = thread.value

      ssl_peer << request
      ssl_socket.read(request.size).should == request

      ssl_socket << response
      ssl_peer.read(response.size).should == response
    end
  end
end
