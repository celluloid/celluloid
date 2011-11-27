module Celluloid
  # Allow methods to directly interact with the actor protocol
  class Receivers
    def initialize
      @handlers = []
    end

    # Receive an asynchronous message
    def receive(&block)
      raise ArgumentError, "receive must be given a block" unless block

      @handlers << [Fiber.current, block]
      Fiber.yield
    end

    # Handle incoming messages
    def handle_message(message)
      handler = nil

      @handlers.each_with_index do |(fiber, block), index|
        if block.call(message)
          handler = index
          break
        end
      end

      if handler
        fiber, _ = @handlers.delete_at handler
        fiber.resume message
        true
      else
        false
      end
    end
  end
end
