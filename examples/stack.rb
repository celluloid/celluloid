#!/usr/bin/env ruby

$LOAD_PATH.push File.expand_path("../lib", __dir__)
require "celluloid/autostart"

# This example builds on basic_usage.rb to show two things about #async: the
# (new) fluent API and the preservation of causality order.
class Stack
  include Celluloid

  attr_reader :ary

  def initialize
    @ary = []
  end

  def push(x)
    @ary.push x
  end
  alias << push

  def pop
    @ary.pop
  end

  def show
    p @ary
  end
end

st = Stack.new

# Schedule three calls to #push some integers on the stack. They will execute
# in order because the calls originated as a sequence of method calls in a
# single thread.
st.async << 1 << 2 << 3

# Schedule a call to show the stack after the three push calls execute.
st.async.show

# Schedule three calls to #pop from the stack.
st.async.pop.pop.pop

# The next (non-async) call is guaranteed to execute after methods previously
# scheduled in this thread. The causal order of calls (order as requested) is
# preserved in the execution order.
st.show
