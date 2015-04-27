class Thread
  def self.mailbox
    Celluloid.mailbox
  end

  def self.receive(timeout = nil, &block)
    Celluloid.receive(timeout, &block)
  end
end

# TODO: Remove link to Interal::Logger
module Celluloid
  Logger = Internals::Logger
end