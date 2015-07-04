unless $CELLULOID_BACKPORTED == false
  class DeprecatedTestEventedMailbox < Celluloid::Mailbox::Evented
    class Reactor
      def initialize
        @condition = ConditionVariable.new
        @mutex = Mutex.new
      end

      def wakeup
        @mutex.synchronize do
          @condition.signal
        end
      end

      def run_once(timeout)
        @mutex.synchronize do
          @condition.wait(@mutex, timeout)
        end
      end

      def shutdown
      end
    end

    def initialize
      super(Reactor)
    end
  end

  RSpec.describe "Deprecated Celluloid::Mailbox::Evented" do
    subject { DeprecatedTestEventedMailbox.new }
    it_behaves_like "a Celluloid Mailbox"
  end
end
