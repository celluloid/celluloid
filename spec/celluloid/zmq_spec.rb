require 'spec_helper'

# find some available ports for ZMQ
ZMQ_PORTS = 10.times.map do
  begin
    server = TCPServer.new('127.0.0.1', 0)
    server.addr[1]
  ensure
    server.close if server
  end
end

describe Celluloid::ZMQ do
  before { @sockets = [] }
  after { @sockets.each(&:close) }
  let(:ports) { ZMQ_PORTS }

  def connect(socket, index=0)
    socket.connect("tcp://127.0.0.1:#{ports[index]}")
    @sockets << socket
    socket
  end

  def bind(socket, index=0)
    socket.bind("tcp://127.0.0.1:#{ports[index]}")
    @sockets << socket
    socket
  end

  describe ".init" do
    it "inits a ZMQ context", :no_init do
      Celluloid::ZMQ.init
      server = bind(Celluloid::ZMQ.context.socket(::ZMQ::REQ))
      client = connect(Celluloid::ZMQ.context.socket(::ZMQ::REP))

      server.send_string("hello world")
      message = ""
      client.recv_string(message)
      message.should eq("hello world")
    end

    it "raises an error when trying to access context and it isn't initialized", :no_init do
      expect { Celluloid::ZMQ.context }.to raise_error(Celluloid::ZMQ::UninitializedError)
    end

    it "raises an error when trying to access context after it is terminated" do
      Celluloid::ZMQ.terminate
      expect { Celluloid::ZMQ.context }.to raise_error(Celluloid::ZMQ::UninitializedError)
      Celluloid::ZMQ.init
      Celluloid::ZMQ.context.should_not be_nil
    end
  end
end
