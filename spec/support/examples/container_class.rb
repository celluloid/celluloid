class SupervisionContainerHelper
  @queue = nil
  class << self
    def reset!
      @queue = Queue.new
    end

    def done!
      @queue << :done
    end

    def pop!
      @queue.pop
    end
  end
end

class MyContainerActor
  include Celluloid

  attr_reader :args

  def initialize(*args)
    @args = args
    ready
  end

  def running?
    :yep
  end

  def ready
    SupervisionContainerHelper.done!
  end
end
