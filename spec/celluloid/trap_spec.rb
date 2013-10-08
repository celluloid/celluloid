require 'spec_helper'

class Bikeshed
  include Celluloid

  attr_reader :color

  def paint(color)
    @color = color
  end
end

describe "Celluloid.trap", actor_system: :global do
  it "handles two signals" do
    shed = Bikeshed.new

    completed = Struct.new(:value).new(:completed)

    green_future = Celluloid::Future.new
    red_future = Celluloid::Future.new

    Celluloid.trap("INFO") do
      shed.paint("green")
      green_future.signal completed
    end

    Process.kill("INFO", $$)

    green_future.value.should == :completed
    shed.color.should == "green"

    Celluloid.trap("USR2") do
      shed.paint("red")
      red_future.signal completed
    end

    Process.kill("USR2", $$)

    red_future.value.should == :completed
    shed.color.should == "red"
  end
end