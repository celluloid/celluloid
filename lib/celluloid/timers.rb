module Celluloid
  # Group functionality for timers
  class Timers
    def initialize
      @timers = []
    end

    # Call the given block after the given interval
    def add(interval, &block)
      @timers << Timer.new(interval, block)
    end

    # Wait for the next timer and fire it
    def wait
      return if @timers.empty?
      timer = @timers.shift

      sleep timer.time - Time.now
      timer.call
    end
  end

  # A proc associated with a particular timestamp
  class Timer
    # How precise are we being here? We're using freaking floats!
    QUANTUM = 0.01

    attr_reader :time

    def initialize(interval, block)
      @block = block
      @time = Time.now + interval
    end

    # Call the associated block
    def call
      @block.call
    end
  end
end
