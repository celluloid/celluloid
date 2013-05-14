class Thread
  def self.mailbox
    Celluloid.mailbox
  end

  def self.receive(timeout = nil, &block)
    Celluloid.receive(timeout, &block)
  end
end
