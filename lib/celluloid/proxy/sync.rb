# A proxy which sends synchronous calls to an actor
class Celluloid::Proxy::Sync < Celluloid::Proxy::AbstractCall
  def respond_to?(meth, include_private = false)
    __class__.instance_methods.include?(meth) || method_missing(:respond_to?, meth, include_private)
  end

  def method_missing(meth, *args, &block)
    raise ::Celluloid::DeadActorError, "attempted to call a dead actor: #{meth}" unless @mailbox.alive?

    if @mailbox == ::Thread.current[:celluloid_mailbox]
      args.unshift meth
      meth = :__send__
      # actor = Thread.current[:celluloid_actor]
      # actor = actor.behavior.subject.bare_object
      # return actor.__send__(*args, &block)
    end

    call = ::Celluloid::Call::Sync.new(::Celluloid.mailbox, meth, args, block)
    @mailbox << call
    call.value
  end
end
