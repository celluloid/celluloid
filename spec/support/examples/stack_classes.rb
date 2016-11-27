class StackWaiter
  QUEUE = Queue.new
  WAITERS = Queue.new
  ACTORS = Queue.new

  class << self
    def forever
      WAITERS << Thread.current
      # de QUEUE.pop
      sleep
    end

    def no_longer
      StackWaiter::ACTORS.pop.terminate until StackWaiter::ACTORS.empty?

      loop do
        break if WAITERS.empty?
        QUEUE << nil
        nicely_end_thread(WAITERS.pop)
      end
    end

    def nicely_end_thread(th)
      return if jruby_fiber?(th)

      status = th.status
      case status
      when nil, false, "dead"
      when "aborting"
        th.join(2) || STDERR.puts("Thread join timed out...")
      when "sleep", "run"
        th.kill
        th.join(2) || STDERR.puts("Thread join timed out...")
      else
        STDERR.puts "unknown status: #{th.status.inspect}"
      end
    end

    def jruby_fiber?(th)
      return false unless RUBY_PLATFORM == "java" && (java_th = th.to_java.getNativeThread)
      /Fiber/ =~ java_th.get_name
    end
  end
end

class StackBlocker
  include Celluloid

  def initialize(threads)
    @threads = threads
  end

  def blocking
    StackWaiter::ACTORS << Thread.current
    @threads << Thread.current
    StackWaiter.forever
  end
end
