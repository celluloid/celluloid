# Monkeypatch Thread to allow lazy access to its Celluloid::Mailbox
class Thread
  def mailbox
    self[:mailbox] ||= Celluloid::Mailbox.new
  end
end