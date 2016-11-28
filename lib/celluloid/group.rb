module Celluloid
  class Group
    attr_accessor :group

    def initialize
      @pid = $PROCESS_ID
      @mutex = Mutex.new
      @group = []
      @running = true
    end

    def assert_active
      raise Celluloid::NotActive unless active?
    end

    def assert_inactive
      return unless active?
      if RUBY_PLATFORM == "java"
        Celluloid.logger.warn "Group is still active"
      else
        raise Celluloid::StillActive
      end
    end

    def each
      to_a.each { |thread| yield thread }
    end

    def forked?
      @pid != $PROCESS_ID
    end

    def to_a
      return [] if forked?
      res = nil
      @mutex.synchronize { res = @group.dup }
      res
    end

    def purge(thread)
      @mutex.synchronize do
        @group.delete(thread)
        begin
          thread.kill
        rescue
          nil
        end
      end
    end

    def each_actor(&block)
      to_a.lazy.select { |t| t[:celluloid_role] == :actor }.each(&block)
    end

    def active?
      @running
    end

    def get
      raise NotImplementedError
    end

    def create
      raise NotImplementedError
    end

    def shutdown
      raise NotImplementedError
    end
  end
end
