require 'bundler/setup'
require 'celluloid/io'

class EchoUNIXClient
  include Celluloid::IO
  finalizer :finalize

  def initialize(socket_path)
    puts "*** connecting to #{socket_path}"
    @socket_path = socket_path
    @socket = UNIXSocket.open(socket_path)
  end

  def echo(msg)
    puts "*** send to server: '#{msg}'"
    @socket.puts(msg)
    data = @socket.readline.chomp
    puts "*** server unswer '#{data}'"
    data
  end

  def finalize
    @socket.close if @socket
  end

end

c = EchoUNIXClient.new("/tmp/sock_test")
c.echo("DATA")
