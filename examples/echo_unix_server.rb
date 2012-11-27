$:.push File.expand_path('../../lib', __FILE__)
require 'celluloid/io'

class EchoUNIXServer
  include Celluloid::IO
    
  attr_reader :socket_path, :server

  def initialize(socket_path)
    puts "*** start server #{socket_path}"
    @socket_path = socket_path
    @server = UNIXServer.open(socket_path)
  end

  def run
    loop { handle_connection! @server.accept }
  end

  def handle_connection(socket)
    loop do
      data = socket.readline
      puts "*** gets data #{data}"
      socket.write(data)
    end
  
  rescue EOFError
    puts "*** disconnected"

  ensure
    socket.close
  end

  def finalize
    if @server
      @server.close
      File.delete(@socket_path)
    end
  end

end

s = EchoUNIXServer.new("/tmp/sock_test")
s.run
