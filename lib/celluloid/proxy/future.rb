# A proxy which creates future calls to an actor
class Celluloid::Proxy::Future < Celluloid::Proxy::AbstractCall
  def method_missing(meth, *args, &block)
    unless @mailbox.alive?
      raise ::Celluloid::DeadActorError, "attempted to call a dead actor: #{meth}"
    end

    if block_given?
      # FIXME: nicer exception
      raise "Cannot use blocks with futures yet"
    end

    future = ::Celluloid::Future.new
    call = ::Celluloid::Call::Sync.new(future, meth, args, block)

    @mailbox << call

    future
  end
end
