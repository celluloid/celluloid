require 'set'

module Celluloid
  class Handlers
    def initialize
      @handlers = Set.new
    end

    def handle(*patterns, &block)
      patterns.each do |pattern|
        handler = Handler.new pattern, block
        @handlers << handler
      end
    end

    # Handle incoming messages
    def handle_message(message)
      if handler = @handlers.find { |h| h.match(message) }
        handler.call message
        handler
      end
    end
  end

  # Methods blocking on a call to receive
  class Handler
    def initialize(pattern, block)
      @pattern = pattern
      @block = block
    end

    # Match a message with this receiver's block
    def match(message)
      @pattern === message
    end

    def call(message)
      @block.call message
    end
  end
end
