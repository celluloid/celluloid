class SubordinateDead < Celluloid::Error; end

class Subordinate
  include Celluloid
  attr_reader :state

  def initialize(state)
    @state = state
  end

  def crack_the_whip
    case @state
    when :idle
      @state = :working
    else
      fail SubordinateDead, "the spec purposely crashed me :("
    end
  end
end
