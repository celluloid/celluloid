#!/usr/bin/env ruby
#
# Worker Pool example
#
# Looking for a way to light up all your cores? This is it! Celluloid::Worker
# lets you create fixed-sized thread pools for executing expensive background
# processing tasks.

PARALLEL_RUBIES = %w(jruby rbx)

$:.push File.expand_path('../../lib', __FILE__)
require 'celluloid/autostart'
require 'digest/sha2'

class Rehasher
  include Celluloid

  def rehash(string, rounds)
    raise ArgumentError, "hurr" unless rounds > 1
    penultimate = (rounds - 1).times.inject(string) { |s| Digest::SHA512.digest(s) }
    Digest::SHA512.hexdigest(penultimate)
  end
end

if $0 == __FILE__
  pool = Rehasher.pool
  puts "Megahashing!"
  if PARALLEL_RUBIES.include?(RUBY_ENGINE)
    puts "Since you're using a Ruby with parallel thread execution, this should light up all your cores"
  elsif RUBY_ENGINE == "ruby"
    puts "Sorry, this Ruby interpreter has a GIL, so this will only use one core"
  end

  futures = %w(i am the very model of a modern major general).map do |word|
    pool.future.rehash(word, 1_000_000)
  end

  p futures.map(&:value)
end
