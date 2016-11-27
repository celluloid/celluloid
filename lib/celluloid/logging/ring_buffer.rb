module Celluloid
  class RingBuffer
    def initialize(size)
      @size = size
      @start = 0
      @count = 0
      @buffer = Array.new(size)
      @mutex = Mutex.new
    end

    def full?
      @count == @size
    end

    def empty?
      @count == 0
    end

    def push(value)
      @mutex.synchronize do
        stop = (@start + @count) % @size
        @buffer[stop] = value
        if full?
          @start = (@start + 1) % @size
        else
          @count += 1
        end
        value
      end
    end
    alias << push

    def shift
      @mutex.synchronize do
        remove_element
      end
    end

    def flush
      values = []
      @mutex.synchronize do
        values << remove_element until empty?
      end
      values
    end

    def clear
      @buffer = Array.new(@size)
      @start = 0
      @count = 0
    end

    private

    def remove_element
      return nil if empty?
      value = @buffer[@start]
      @buffer[@start] = nil
      @start = (@start + 1) % @size
      @count -= 1
      value
    end
  end
end
