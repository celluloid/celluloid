require 'celluloid'

module Celluloid
  # Monitors futures and acts on them as they complete.
  class FuturePlexer
    # Collection of futures for which you're waiting.
    attr_accessor :futures

    def initialize(futures)
      self.futures = futures.each(&:subscribe)
    end

    # Selects futures that are ready, optionally in a given timeout.
    #
    # If invoked with a block, each completed future will be yielded to
    # it. Otherwise an array of completed futures is returned.
    def select(timeout = nil, &block)
      raise DrainedError, 'No futures left.' if drained?

      Celluloid.receive(timeout) do |msg|
        msg.is_a?(Celluloid::Future::Result) && futures.include?(msg.future)
      end

      results = []
      futures.each do |future|
        if future.ready?
          results << future.value
          futures.delete(future)
        end
      end

      if block_given?
        results.map(&block)
      else
        results
      end
    end

    # Whether all futures have completed.
    def drained?
      futures.empty?
    end
  end
end
