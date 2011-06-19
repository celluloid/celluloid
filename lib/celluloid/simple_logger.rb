module Celluloid
  # Basic logging functionality which only prints to STDOUT if it's a tty
  class SimpleLogger
    def initialize(tty = STDOUT)
      @tty = tty
    end
    
    def error(message)
      return unless @tty.tty?
      @tty.puts message
    end
  end
end