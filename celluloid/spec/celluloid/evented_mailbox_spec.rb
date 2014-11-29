require 'spec_helper'

class TestEventedMailbox < Celluloid::EventedMailbox
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

describe Celluloid::EventedMailbox do
  subject { TestEventedMailbox.new }
  it_behaves_like "a Celluloid Mailbox"
end
