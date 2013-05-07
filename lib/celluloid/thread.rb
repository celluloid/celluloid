require 'celluloid/fiber'

module Celluloid
  class Thread < ::Thread
    # FIXME: these should be replaced using APIs on Celluloid::Thread itself
    # e.g. Thread.current[:celluloid_actor] => Thread.current.actor
    CELLULOID_LOCALS = [
      :celluloid_actor,
      :celluloid_mailbox,
      :celluloid_queue,
      :celluloid_task,
      :celluloid_chain_id
    ]

    def celluloid?
      true
    end

    # Obtain the Celluloid::Actor object for this thread
    def actor
      self[:celluloid_actor]
    end

    # Obtain the Celluloid task object for this thread
    def task
      self[:celluloid_task]
    end

    # Obtain the Celluloid mailbox for this thread
    def mailbox
      self[:celluloid_mailbox]
    end

    # Obtain the call chain ID for this thread
    def call_chain_id
      self[:celluloid_chain_id]
    end

    #
    # Override default thread local behavior, making thread locals actor-local
    #

    # Obtain an actor-local value
    def [](key)
      actor = super(:celluloid_actor)
      if !actor || CELLULOID_LOCALS.include?(key)
        super(key)
      else
        actor.locals[key]
      end
    end

    # Set an actor-local value
    def []=(key, value)
      actor = self[:celluloid_actor]
      if !actor || CELLULOID_LOCALS.include?(key)
        super(key, value)
      else
        actor.locals[key] = value
      end
    end

    # Obtain the keys to all actor-locals
    def keys
      actor = self[:celluloid_actor]
      if actor
        actor.locals.keys
      else
        super
      end
    end

    # Is the given actor local set?
    def key?(key)
      actor = self[:celluloid_actor]
      if actor
        actor.locals.has_key?(key)
      else
        super
      end
    end

    # Clear thread state so it can be reused via thread pools
    def recycle
      # This thread local mediates access to the others, so we must clear it first
      self[:celluloid_actor] = nil

      # Clearing :celluloid_queue would break the thread pool!
      keys.each { |key| self[key] = nil unless key == :celluloid_queue }
    end
  end
end
