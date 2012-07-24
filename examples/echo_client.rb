#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'celluloid/io'

class EchoClient
  include Celluloid::IO

  def initialize(host, port)
    puts "*** Connecting to echo server on #{host}:#{port}"

    # This is actually creating a Celluloid::IO::TCPSocket
    @socket = TCPSocket.new(host, port)
  end

  def echo(s)
    @socket.write(s)
    @socket.readpartial(4096)
  end

end

client = EchoClient.new("127.0.0.1", 1234)
puts client.echo("TEST FOR ECHO")
