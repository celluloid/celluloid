require 'spec_helper'

class Bikeshed
  include Celluloid

  attr_reader :color

  def paint(color)
    @color = color
  end
end

describe "Celluloid.trap" do
  it "handles INFO" do
    shed = Bikeshed.new

    Celluloid.trap("INFO") do
      shed.paint("green")
    end

    Process.kill("INFO", $$)
    
    shed.color.should == "green"
  end
end