require 'socket'

module Celluloid
  # A TCPServer that runs as an actor
  class TCPServer
    include Celluloid::IO

    # Bind a TCP server to the given host and port
    def initialize(host, port)
      @server = ::TCPServer.new host, port
      run!
    end

    # Run the TCP server event loop
    def run
      while true
        wait_readable(@server)
        on_connect @server.accept
      end
    end

    # Terminate this server
    def terminate
      @server.close
      super
    end

    # Called whenever a new connection is opened
    def on_connect(connection)
      connection.close
    end
  end
end
