class CallExampleActor
  include Celluloid

  def initialize(next_actor = nil)
    @next = next_actor
  end

  def actual_method; end

  def inspect
    raise "Don't call!"
  end

  def chained_call_ids
    [call_chain_id, @next.call_chain_id]
  end
end

# de DEPRECATE:

class DeprecatedCallExampleActor
  include Celluloid

  def initialize(next_actor = nil)
    @next = next_actor
  end

  def actual_method; end

  def inspect
    raise "Please don't call me! I'm not ready yet!"
  end

  def chained_call_ids
    [call_chain_id, @next.call_chain_id]
  end
end
