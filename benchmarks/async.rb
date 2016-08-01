#!/usr/bin/env ruby

require 'benchmark'
require 'benchmark/ips'
require 'celluloid'

class CountDownLatch
    include Celluloid
    def initialize(count = 1)
        @mutex = Mutex.new
        @mutex.synchronize { @count = count }
    end

    def count_down
        @mutex.synchronize do
            @count -= 1 if @count > 0
        end
    end

    def count
        @mutex.synchronize { @count }
    end

    def foo(latch = nil)
        latch.count_down if latch
    end

end

IPS_NUM = 100

Benchmark.ips do |bm|
    latch = CountDownLatch.new(IPS_NUM)
    bm.report('Async - Count down latch') do
        IPS_NUM.times { latch.async.count_down }
    end

    # bm.report('Sync - Count down latch') do
    #     IPS_NUM.times { latch.count_down }
    # end
end

# Async - Count down latch
# 418.000  i/100ms
# Sync - Count down latch
# 1.000  i/100ms
# -------------------------------------------------
# Async - Count down latch
# 7.873k (±55.7%) i/s -     22.572k
# Sync - Count down latch
# 0.009  (± 0.0%) i/s -      1.000  in 116.511969s