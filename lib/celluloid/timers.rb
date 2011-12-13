module Celluloid
  # Low precision timers implemented in pure Ruby
  class Timers
    def initialize
      @timers = []
    end

    # Call the given block after the given interval
    def add(interval, &block)
      timer = Timer.new(interval, block)
      @timers.insert(index(timer), timer)
      timer
    end

    # Wait for the next timer and fire it
    def wait
      return if @timers.empty?

      int = interval
      sleep int if int >= Timer::QUANTUM
      fire
    end

    # Interval to wait until when the next timer will fire
    def interval
      @timers.first.time - Time.now unless empty?
    end

    # Fire all timers that are ready
    def fire
      return if @timers.empty?

      time = Time.now
      while not empty? and time > @timers.first.time
        timer = @timers.shift
        timer.call
      end
    end

    # Remove a given timer from the set we're monitoring
    def cancel(timer)
      @timers.delete timer
    end

    # Are there any timers pending?
    def empty?
      @timers.empty?
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

  # An individual timer set to fire a given proc at a given time
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
