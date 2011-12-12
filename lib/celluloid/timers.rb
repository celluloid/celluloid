module Celluloid
  # Group functionality for timers
  class Timers
    def initialize
      @timers = []
    end

    # Call the given block after the given interval
    def add(interval, &block)
      timer = Timer.new(interval, block)
      @timers.insert(index(timer), timer)
    end

    # Wait for the next timer and fire it
    def wait
      return if @timers.empty?
      timer = @timers.shift

      sleep timer.time - Time.now
      timer.call
    end

    # Index where a timer would be located in the sorted timers array
    def index(timer)
      l, r = 0, @timers.size - 1

      while l <= r
        m = (r + l) / 2
        if timer < @timers.at(m)
          r = m - 1
        else
          l = m + 1
        end
      end
      l
    end
  end

  # A proc associated with a particular timestamp
  class Timer
    include Comparable

    # How precise are we being here? We're using freaking floats!
    QUANTUM = 0.01

    attr_reader :time

    def initialize(interval, block)
      @block = block
      @time = Time.now + interval
    end

    def <=>(other)
      @time <=> other.time
    end

    # Call the associated block
    def call
      @block.call
    end
  end
end
