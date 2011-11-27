# Monkeypatch Thread to allow lazy access to its Celluloid::Mailbox
class Thread
  # Retrieve the mailbox for the current thread or lazily initialize it
  def self.mailbox
    current[:mailbox] ||= Celluloid::Mailbox.new
  end
end
