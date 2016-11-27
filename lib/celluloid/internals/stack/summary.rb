module Celluloid
  module Internals
    class Stack
      class Summary < Stack
        def initialize(threads)
          super(threads)
          snapshot
        end
      end
    end
  end
end
