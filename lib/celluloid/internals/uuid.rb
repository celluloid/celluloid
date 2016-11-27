require "securerandom"

module Celluloid
  module Internals
    # Clearly Ruby doesn't have enough UUID libraries
    # This one aims to be fast and simple with good support for multiple threads
    # If there's a better UUID library I can use with similar multithreaded
    # performance, I certainly wouldn't mind using a gem for this!
    module UUID
      values = SecureRandom.hex(9).match(/(.{8})(.{4})(.{3})(.{3})/)
      PREFIX = "#{values[1]}-#{values[2]}-4#{values[3]}-8#{values[4]}".freeze
      BLOCK_SIZE = 0x10000

      @counter = 0
      @counter_mutex = Mutex.new

      def self.generate
        thread = Thread.current

        unless thread.uuid_limit
          @counter_mutex.synchronize do
            block_base = @counter
            @counter += BLOCK_SIZE
            thread.uuid_counter = block_base
            thread.uuid_limit   = @counter - 1
          end
        end

        counter = thread.uuid_counter
        if thread.uuid_counter >= thread.uuid_limit
          thread.uuid_counter = thread.uuid_limit = nil
        else
          thread.uuid_counter += 1
        end

        "#{PREFIX}-#{format('%012x', counter)}".freeze
      end
    end
  end
end
