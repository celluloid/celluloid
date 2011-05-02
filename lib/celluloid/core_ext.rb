# Monkeypatch Thread to allow lazy access to its Celluloid::Mailbox
class Thread
  def mailbox
    @mailbox ||= Celluloid::Mailbox.new
  end
end