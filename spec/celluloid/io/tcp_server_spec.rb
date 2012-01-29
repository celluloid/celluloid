require 'spec_helper'

describe Celluloid::IO::TCPServer do
  context :accept do
    let(:port)   { 10103 }
    subject      { Celluloid::IO::TCPServer.new("127.0.0.1", port) }
    after(:each) { subject.close unless subject.closed? }

    it "accepts a connection and returns a TCPSocket" do
      class ExampleServer
        include Celluloid::IO
        
        def initialize(socket)
          @socket = socket
          @data = nil
          
          accept!
        end
        
        def accept
          client = @socket.accept
          @data = client.read(5)
          client << "goodbye"
          client.close
        end
        
        def data
          @data
        end
      end
      
      server = ExampleServer.new(subject)
      socket = TCPSocket.new('127.0.0.1', port)
      
      socket.write('hello')
      socket.shutdown(1) # we are done with sending
      socket.read.should == 'goodbye'
      
      server.data.should == 'hello'
      server.terminate
      socket.close
    end
  end
end