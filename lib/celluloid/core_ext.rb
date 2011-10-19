# Monkeypatch Thread to allow lazy access to its Celluloid::Mailbox
class Thread
  # Slightly insane global lock for lazy-initializing the mailbox of ANY thread
  @@mailbox_lock = Mutex.new

  # Retrieve the current mailbox or lazily initialize it
  def mailbox
    # I'm aware this is super ghetto but it's only here for threads created
    # outside of Celluloid itself. Celluloid is good about initializing the
    # mailbox thread local itself non-lazily.
    self[:mailbox] || begin
      @@mailbox_lock.synchronize do
        self[:mailbox] ||= Celluloid::Mailbox.new
      end
    end
  end
end
