#!/usr/bin/env ruby

$:.push File.expand_path('../../lib', __FILE__)
require 'celluloid/io'

class EchoClient
  include Celluloid::IO

  def initialize(host, port)
    puts "*** Connecting to echo server on #{host}:#{port}"

    @socket = TCPSocket.from_ruby_socket(::TCPSocket.new(host, port))
  end

  def echo(s)
    @socket.write(s)
    actor = Celluloid.current_actor
    actor.wait_readable @socket
    puts @socket.read_nonblock(4096)
  end

end

client = EchoClient.new("127.0.0.1", 1234)
client.echo("HONKY TONKY")
client.echo("FONKY FONK")
client.echo("BIPPITY BOP")

