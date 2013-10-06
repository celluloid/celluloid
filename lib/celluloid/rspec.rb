require File.expand_path('../../../spec/support/example_actor_class', __FILE__)
require File.expand_path('../../../spec/support/actor_examples', __FILE__)
require File.expand_path('../../../spec/support/mailbox_examples', __FILE__)

module Celluloid
  # Timer accuracy enforced by the tests (50ms)
  TIMER_QUANTUM = 0.05
end

$CELLULOID_DEBUG = true

require 'celluloid/test'
