class Celluloid::Multiplex

end


=begin
#de https://github.com/celluloid/celluloid/issues/632
# Acts like an array and receives futures. Will yield them as
# they become ready.

class HackedMultiplexer
  include Celluloid
  include Enumerable

  LOOP_BREATHER = 0.0126

  def initialize
    @not_ready = []
  end

  def push(obj)
    @not_ready.push(obj)
  end
  alias_method :<<, :push

  def each(&blk)
    loop do
      ready = @not_ready.select { |future| future.ready? }
      @not_ready -= ready

      ready.each { |future| yield(future) }

      break if @not_ready.empty?
    end
  end

  def resolve(arr)

  end
end
=end
