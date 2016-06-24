module Specs
  class FakeLogger
    class << self
      def current
        allowed_logger.first
      end

      attr_accessor :allowed_logger
    end

    def initialize(real_logger, example)
      @mutex = Mutex.new
      @real_logger = real_logger
      @crashes = Queue.new
      @details = nil
      @example = example
      self.class.allowed_logger = [self, example]
    end

    def crash(*args)
      check
      raise "Testing block has already ended!" if @details
      @crashes << [args, caller.dup]
    end

    def debug(*args)
      check
      @real_logger.debug(*args)
    end

    def warn(*args)
      check
      @real_logger.warn(*args)
    end

    def with_backtrace(_backtrace)
      check
      yield self
    end

    def crashes
      check
      @mutex.synchronize do
        return @details if @details
        @details = []
        @details << @crashes.pop until @crashes.empty?
        @crashes = nil
        @details
      end
    end

    def crashes?
      check
      !crashes.empty?
    end

    private

    def check
      return if self.class.allowed_logger.first == self

      raise "Incorrect logger used:"\
        " active/allowed: \n#{clas.allowed_logger.inspect},\n"\
        " actual/self: \n#{[self, @example].inspect}\n"\
        " (maybe an actor from another test is still running?)"
    end
  end
end
