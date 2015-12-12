# A proxy which sends asynchronous calls to an actor
class Celluloid::Proxy::Async < Celluloid::Proxy::AbstractCall
  def method_missing(meth, *args, &block)
    if @mailbox == ::Thread.current[:celluloid_mailbox]
      args.unshift meth
      meth = :__send__
    end
    if block_given?
      # FIXME: nicer exception
      fail "Cannot use blocks with async yet"
    end
    @mailbox << ::Celluloid::Call::Async.new(meth, args, block)
    self
  end
end
