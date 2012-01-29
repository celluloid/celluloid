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


    it "can be interrupted by Thread#kill" do
      t = Thread.new { subject.accept }

      Thread.pass while t.status and t.status != "sleep"

      # kill thread, ensure it dies in a reasonable amount of time
      t.kill
      a = 1
      while a < 2000
        break unless t.alive?
        Thread.pass
        sleep 0.2
        a += 1
      end
      a.should < 2000
    end

    it "can be interrupted by Thread#raise" do
      t = Thread.new { subject.accept }

      Thread.pass while t.status and t.status != "sleep"

      # raise in thread, ensure the raise happens
      ex = Exception.new
      t.raise ex
      lambda { t.join }.should raise_error(Exception)
    end
  end
end