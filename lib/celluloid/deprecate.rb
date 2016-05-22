class Thread
  def self.mailbox
    Celluloid.mailbox
  end

  def self.receive(timeout = nil, &block)
    Celluloid.receive(timeout, &block)
  end
end

module Celluloid
  ActorSystem = Actor::System

  SyncCall = Call::Sync
  AsyncCall = Call::Async
  BlockCall = Call::Block

  AbstractProxy = Proxy::Abstract
  ActorProxy = Proxy::Actor
  AsyncProxy = Proxy::Async
  BlockProxy = Proxy::Block
  CellProxy = Proxy::Cell
  FutureProxy = Proxy::Future
  SyncProxy = Proxy::Sync

  EventedMailbox = Mailbox::Evented
  InternalPool = Group::Pool

  TaskThread = Task::Threaded
  TaskFiber = Task::Fibered

  Task::TerminatedError = TaskTerminated
  Task::TimeoutError = TaskTimeout
end
