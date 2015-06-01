class Worker
  include Celluloid

  def initialize
    @mutex = Mutex.new
  end

  def wait
    @mutex.synchronize do
      sleep 10
    end
  end

  def second_wait
    exclusive do
      sleep 1
    end
  end

  def wait_for(worker)
    worker.wait
  end
end

worker1 = Worker.new
worker2 = Worker.new

worker1.async.wait
worker2.wait_for(worker1)

