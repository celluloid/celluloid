module Specs
  def self.sleep_and_wait_until(timeout = 10)
    t1 = Time.now.to_f
    ::Timeout.timeout(timeout) do
      loop until yield
    end

    diff = Time.now.to_f - t1
    STDERR.puts "wait took a bit long: #{diff} seconds" if diff > Specs::TIMER_QUANTUM
  rescue Timeout::Error
    t2 = Time.now.to_f
    raise "Timeout after: #{t2 - t1} seconds"
  end
end
