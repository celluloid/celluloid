module Celluloid
  module Internals
    class Stack
      class Dump < Stack
        def initialize(threads)
          super(threads)
          snapshot(true)
        end
      end
    end
  end
end
