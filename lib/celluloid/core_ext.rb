require 'celluloid/fiber'

# Monkeypatch Thread to allow lazy access to its Celluloid::Mailbox
class Thread
  # Retrieve the mailbox for the current thread or lazily initialize it
  def self.mailbox
    current[:mailbox] ||= Celluloid::Mailbox.new
  end
end

class Fiber
  # Celluloid::Task associated with this Fiber
  attr_accessor :task
end
