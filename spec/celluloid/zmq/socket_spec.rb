require 'spec_helper'
require 'celluloid/rspec'

describe Celluloid::ZMQ::Socket, actor_system: :global do

  it "allows setting and getting ZMQ options on the socket" do
    socket = Celluloid::ZMQ::RepSocket.new
    socket.set(::ZMQ::IDENTITY, "Identity")

    identity = socket.get(::ZMQ::IDENTITY)

    identity.should == "Identity"
  end

end
