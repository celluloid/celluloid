require 'celluloid/fiber'

class Thread
  attr_accessor :uuid_counter, :uuid_limit
end
