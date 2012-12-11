require 'celluloid/fiber'

# Monkeypatch Thread to allow lazy access to its Celluloid::Mailbox
class Thread
  attr_accessor :uuid_counter, :uuid_limit

  # Retrieve the mailbox for the current thread or lazily initialize it
  def self.mailbox
    current[:celluloid_mailbox] ||= Celluloid::Mailbox.new
  end

  # Receive a message either as an actor or through the local mailbox
  def self.receive(timeout = nil, &block)
    if Celluloid.actor?
      Celluloid.receive(timeout, &block)
    else
      mailbox.receive(timeout, &block)
    end
  end
end