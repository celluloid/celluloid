require 'celluloid/fiber'

module Celluloid
  class Thread < ::Thread
    def celluloid?
      true
    end
  end
end
