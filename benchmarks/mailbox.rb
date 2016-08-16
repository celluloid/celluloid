#!/usr/bin/env ruby

require "rubygems"
require "bundler/setup"
require "celluloid/autostart"
require "benchmark"

message = :ohai

BM_COUNT = 1_000_000

Benchmark.bmbm do |bm|
  mailbox = Celluloid.mailbox

  bm.report("mailbox send message") do
    BM_COUNT.times do
      mailbox << message
    end
  end

  bm.report("mailbox receive message") do
    BM_COUNT.times do
      mailbox.receive
    end
  end
end

# Rehearsal -----------------------------------------------------------
# mailbox send message      0.280000   0.000000   0.280000 (  0.286290)
# mailbox receive message   1.600000   0.020000   1.620000 (  1.617234)
# -------------------------------------------------- total: 1.900000sec
#
# user     system      total        real
# mailbox send message      0.290000   0.000000   0.290000 (  0.302368)
# mailbox receive message   1.630000   0.030000   1.660000 (  1.650998)
