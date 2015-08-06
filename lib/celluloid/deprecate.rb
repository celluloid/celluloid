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
  SyncCall = Call::Sync
  EventedMailbox = Mailbox::Evented
  InternalPool = Group::Pool
  TaskThread = Task::Threaded
  TaskFiber = Task::Fibered
  ActorSystem = Actor::System
  Task::TerminatedError = TaskTerminated
  Task::TimeoutError = TaskTimeout
end
