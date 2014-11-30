require 'spec_helper'

describe Celluloid::IO do
  context "copy_stream" do
    let(:host) { "127.0.0.1" }
    let(:port) { 23456 }

    it "copies streams from Celluloid::IO sockets" do
      server = described_class::TCPServer.new(host, port)
      client = ::TCPSocket.new(host, port)
      peer   = server.accept
      expect(peer).to be_a described_class::TCPSocket

      my_own_bits = File.read(__FILE__)
      file = File.open(__FILE__, 'r')

      described_class.copy_stream(file, peer)
      expect(client.read(file.stat.size)).to eq my_own_bits
    end
  end
end