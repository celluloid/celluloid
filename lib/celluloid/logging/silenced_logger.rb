module Celluloid
  module SilencedLogger
    def silence
      @silenced = true
    end

    def unsilence
      @silenced = false
    end

    def silenced?
      @silenced ||= false
    end
  end
end
