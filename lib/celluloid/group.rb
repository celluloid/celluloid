module Celluloid
  class Group
    class NotImplemented < StandardError; end
    class StillActive < StandardError; end
    class NotActive < StandardError; end

    attr_accessor :group

    def initialize
      @mutex = Mutex.new
      @group = []
      @running = true
    end

    def assert_active
      fail NotActive unless active?
    end

    def assert_inactive
      return unless active?
      if RUBY_PLATFORM == "java"
        Celluloid.logger.warn "Group is still active"
      else
        fail StillActive
      end
    end

    def each
      to_a.each { |thread| yield thread }
    end

    def to_a
      res = nil
      @mutex.synchronize { res = @group.dup }
      res
    end

    def purge(thread)
      @mutex.synchronize do
        @group.delete(thread)
        thread.kill rescue nil
      end
    end

    def each_actor(&block)
      to_a.lazy.select { |t| t[:celluloid_role] == :actor }.each(&block)
    end

    def active?
      @running
    end

    def get
      fail NotImplemented
    end

    def create
      fail NotImplemented
    end

    def shutdown
      fail NotImplemented
    end
  end
end
