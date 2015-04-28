require "celluloid/fiber"

module Celluloid
  class Thread < ::Thread
    def celluloid?
      true
    end

    attr_accessor :busy

    # Obtain the role of this thread
    def role
      self[:celluloid_role]
    end

    def role=(role)
      self[:celluloid_role] = role
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

    def <<(proc)
      self[:celluloid_queue] << proc
      self
    end
  end
end
