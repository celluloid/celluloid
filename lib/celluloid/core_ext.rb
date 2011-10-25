# Monkeypatch Thread to allow lazy access to its Celluloid::Mailbox
class Thread
  # Retrieve the current mailbox or lazily initialize it
  def mailbox
    self[:mailbox] || begin
      if Thread.current != self
        raise "attempt to access an uninitialized mailbox"
      end

      self[:mailbox] = Celluloid::Mailbox.new
    end
  end
end
