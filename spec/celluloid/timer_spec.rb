require 'spec_helper'

class EveryActor
  include Celluloid

  def initialize
    @trace = []
    @times = []
    @start = Time.now
    
    every(1) { log(1) }
    every(2) { log(2) }
    every(1) { log(11) }
    every(2) { log(22) }
  end
  
  def log(t)
    @trace << t
    
    offset = Time.now - @start
    @times << offset
    
    # puts "log(#{t}) @ #{offset}"
  end
  
  attr :trace
  attr :times
end

describe Celluloid::Actor do
  it "run every(t) task several times" do
    Celluloid.boot
    
    every_actor = EveryActor.new
    
    sleep 5.5
    
    times = every_actor.times
    trace = every_actor.trace
    
    Celluloid.shutdown
    
    expect(trace.count(1)).to be == 5
    expect(trace.count(11)).to be == 5
    expect(trace.count(2)).to be == 2
    expect(trace.count(22)).to be == 2
  end
end
