require 'bundler/setup'
require 'celluloid/io'

class EchoUNIXServer
  include Celluloid::IO
  finalizer :finalize

  attr_reader :socket_path, :server

  def initialize(socket_path)
    puts "*** start server #{socket_path}"
    @socket_path = socket_path
    @server = UNIXServer.open(socket_path)
    async.run
  end

  def run
    loop { async.handle_connection @server.accept }
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

supervisor = EchoUNIXServer.supervise("/tmp/sock_test")
trap("INT") { supervisor.terminate; exit }
sleep
