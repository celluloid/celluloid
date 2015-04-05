module Celluloid
  class Group

    class NotImplemented < StandardError; end
    class StillActive < StandardError; end
    class NotActive < StandardError; end

    attr_accessor :group

    def initialize options={}
      @mutex = Mutex.new
      @group = []
      @running = true
    end

    def assert_active
      raise NotActive unless active?
    end

    def assert_inactive
      return unless active?
      if defined?(JRUBY_VERSION)
        Celluloid.logger.warn "Group is still active"
      else
        raise StillActive
      end
    end

    def active?
      @running
    end

    def get
      raise NotImplemented
    end

    def create
      raise NotImplemented
    end

    def each
      raise NotImplemented
    end

    def shutdown
      raise NotImplemented
    end

  end
end