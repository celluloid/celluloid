#!/usr/bin/env ruby

$:.push File.expand_path('../../lib', __FILE__)
require 'celluloid/cellulate'

class BaseFibber
  def fib(n)
    n < 2 ? n : fib(n-1) + fib(n-2)
  end
end

class Fibber
  include Celluloid

  def fib(n)
    n < 2 ? n : fib(n-1) + fib(n-2)
  end
end

fibber = Fibber.new
future = fibber.future(:fib,10)

base_fibber = BaseFibber.new
begin
  base_future = base_fibber.future(:fib,11)
rescue => e
  puts "We failed because we dont know the future: #{e}"
end
puts "#{base_fibber.class} methods count before conversion: #{base_fibber.methods.count}"
base_fibber.extend(Celluloid::Cellulate)
# call protected method
base_fibber = base_fibber.send(:cellulate)
puts "#{base_fibber.class} methods count after conversion: #{base_fibber.methods.count}"

base_future = base_fibber.future(:fib,11)

puts "Everyone is now clairvoyant: future == #{future.value} and base_future == #{base_future.value}"

