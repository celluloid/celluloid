require 'celluloid/rspec/example_actor_class'
require 'celluloid/rspec/actor_examples'
require 'celluloid/rspec/mailbox_examples'
require 'celluloid/rspec/task_examples'

module Celluloid
  # Timer accuracy enforced by the tests (50ms)
  TIMER_QUANTUM = 0.05
end

$CELLULOID_DEBUG = true

require 'celluloid/test'
