# Monkeypatch Thread to allow lazy access to its Celluloid::Mailbox
class Thread
  def celluloid_mailbox
    @celluloid_mailbox ||= Celluloid::Mailbox.new
  end
end