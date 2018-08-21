#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path("../lib", __dir__)
require "celluloid/autostart"

module Enumerable
  # Simple parallel map using Celluloid::Futures
  def pmap(&block)
    futures = map { |elem| Celluloid::Future.new(elem, &block) }
    futures.map(&:value)
  end
end

p 100.times.pmap { |n| n * 2 }
