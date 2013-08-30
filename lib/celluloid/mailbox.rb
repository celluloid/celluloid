require 'thread'

module Celluloid
  class MailboxDead < Celluloid::Error; end # you can't receive from the dead
  class MailboxShutdown < Celluloid::Error; end # raised if the mailbox can no longer be used

  # Actors communicate with asynchronous messages. Messages are buffered in
  # Mailboxes until Actors can act upon them.
  class Mailbox
    include Enumerable

    # A unique address at which this mailbox can be found
    attr_reader :address
    attr_accessor :max_size

    def initialize
      @address   = Celluloid.uuid
      @messages  = []
      @mutex     = Mutex.new
      @dead      = false
      @condition = ConditionVariable.new
      @max_size  = nil
    end

    # Add a message to the Mailbox
    def <<(message)
      @mutex.lock
      begin
        if mailbox_full || @dead
          dead_letter(message)
          return
        end
        if message.is_a?(SystemEvent)
          # SystemEvents are high priority messages so they get added to the
          # head of our message queue instead of the end
          @messages.unshift message
        else
          @messages << message
        end

        @condition.signal
        nil
      ensure
        @mutex.unlock rescue nil
      end
    end

    # Receive a message from the Mailbox
    def receive(timeout = nil, &block)
      message = nil

      @mutex.lock
      begin
        raise MailboxDead, "attempted to receive from a dead mailbox" if @dead

        begin
          message = next_message(&block)

          unless message
            if timeout
              now = Time.now
              wait_until ||= now + timeout
              wait_interval = wait_until - now
              return if wait_interval <= 0
            else
              wait_interval = nil
            end

            @condition.wait(@mutex, wait_interval)
          end
        end until message

        message
      ensure
        @mutex.unlock rescue nil
      end
    end

    # Retrieve the next message in the mailbox
    def next_message
      message = nil

      if block_given?
        index = @messages.index do |msg|
          yield(msg) || msg.is_a?(SystemEvent)
        end

        message = @messages.slice!(index, 1).first if index
      else
        message = @messages.shift
      end

      message
    end

    # Shut down this mailbox and clean up its contents
    def shutdown
      raise MailboxDead, "mailbox already shutdown" if @dead

      @mutex.lock
      begin
        yield if block_given?
        messages = @messages
        @messages = []
        @dead = true
      ensure
        @mutex.unlock rescue nil
      end

      messages.each do |msg|
        dead_letter msg
        msg.cleanup if msg.respond_to? :cleanup
      end
      true
    end

    # Is the mailbox alive?
    def alive?
      !@dead
    end

    # Cast to an array
    def to_a
      @mutex.synchronize { @messages.dup }
    end

    # Iterate through the mailbox
    def each(&block)
      to_a.each(&block)
    end

    # Inspect the contents of the Mailbox
    def inspect
      "#<#{self.class}:#{object_id.to_s(16)} @messages=[#{map { |m| m.inspect }.join(', ')}]>"
    end

    # Number of messages in the Mailbox
    def size
      @mutex.synchronize { @messages.size }
    end

    private

    def dead_letter(message)
      Logger.debug "Discarded message (mailbox is dead): #{message}" if $CELLULOID_DEBUG
    end

    def mailbox_full
      @max_size && @messages.size >= @max_size
    end
  end
end
