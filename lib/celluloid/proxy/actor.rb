# A proxy which controls the Actor lifecycle
class Celluloid::Proxy::Actor < Celluloid::Proxy::Abstract
  attr_reader :thread, :mailbox

  def initialize(mailbox, thread)
    @mailbox = mailbox
    @thread = thread
  end

  def inspect
    # TODO: use a system event to fetch actor state: tasks?
    "#<Celluloid::Proxy::Actor(#{@mailbox.address}) alive>"
  rescue DeadActorError
    "#<Celluloid::Proxy::Actor(#{@mailbox.address}) dead>"
  end

  def alive?
    @mailbox.alive?
  end

  def dead?
    !alive?
  end

  # Terminate the associated actor
  def terminate
    terminate!
    ::Celluloid::Actor.join(self)
    nil
  end

  # Terminate the associated actor asynchronously
  def terminate!
    ::Kernel.raise ::Celluloid::DeadActorError, "actor already terminated" unless alive?
    @mailbox << ::Celluloid::TerminationRequest.new
  end
end
