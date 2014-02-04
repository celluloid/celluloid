require 'spec_helper'

describe Celluloid::ZMQ do
  before { @sockets = [] }
  after { @sockets.each(&:close) }

  def connect(socket, index=0)
    socket.connect("inproc://celluloid-spec-#{index}")
    @sockets << socket
    socket
  end

  def bind(socket, index=0)
    socket.bind("inproc://celluloid-spec-#{index}")
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

    it "can set ZMQ context manually", :no_init do
      context = ::ZMQ::Context.new(1)
      begin
        Celluloid::ZMQ.context = context
        Celluloid::ZMQ.context.should eq(context)
      ensure
        context.terminate
      end
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

  describe Celluloid::ZMQ::RepSocket do
    let(:actor) do
      Class.new do
        include Celluloid::ZMQ

        finalizer :close_socket

        def initialize(index)
          @socket = Celluloid::ZMQ::RepSocket.new
          @socket.connect("inproc://celluloid-spec-#{index}")
        end

        def say_hi
          "Hi!"
        end

        def fetch
          @socket.read
        end

        def close_socket
          @socket.close
        end
      end
    end

    it "receives messages" do
      server = bind(Celluloid::ZMQ.context.socket(::ZMQ::REQ))
      client = actor.new(0)

      server.send_string("hello world")
      result = client.fetch
      result.should eq("hello world")
    end

    it "suspends actor while waiting for message" do
      server = bind(Celluloid::ZMQ.context.socket(::ZMQ::REQ))
      client = actor.new(0)

      result = client.future.fetch
      client.say_hi.should eq("Hi!")
      server.send_string("hello world")
      result.value.should eq("hello world")
    end
  end

  describe Celluloid::ZMQ::ReqSocket do
    let(:actor) do
      Class.new do
        include Celluloid::ZMQ

        finalizer :close_socket

        def initialize(index)
          @socket = Celluloid::ZMQ::ReqSocket.new
          @socket.connect("inproc://celluloid-spec-#{index}")
        end

        def say_hi
          "Hi!"
        end

        def send(message)
          @socket.write(message)
          true
        end

        def close_socket
          @socket.close
        end
      end
    end

    it "sends messages" do
      client = bind(Celluloid::ZMQ.context.socket(::ZMQ::REP))
      server = actor.new(0)

      server.send("hello world")

      message = ""
      client.recv_string(message)
      message.should eq("hello world")
    end

    it "suspends actor while waiting for message to be sent" do
      client = bind(Celluloid::ZMQ.context.socket(::ZMQ::REP))
      server = actor.new(0)

      result = server.future.send("hello world")

      server.say_hi.should eq("Hi!")

      message = ""
      client.recv_string(message)
      message.should eq("hello world")

      result.value.should be_true
    end
  end
end
