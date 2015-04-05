class TestMachine
  include Celluloid::FSM

  def initialize
    super
    @fired = false
  end

  state :callbacked do
    @fired = true
  end

  state :pre_done, :to => :done
  state :another, :done

  def fired?; @fired end
end

class CustomDefaultMachine
  include Celluloid::FSM

  default_state :foobar
end

RSpec.describe Celluloid::FSM, actor_system: :global do
  subject { TestMachine.new }

  it "starts in the default state" do
    expect(subject.state).to eq(TestMachine.default_state)
  end

  it "transitions between states" do
    expect(subject.state).not_to be :done
    subject.transition :done
    expect(subject.state).to be :done
  end

  it "fires callbacks for states" do
    expect(subject).not_to be_fired
    subject.transition :callbacked
    expect(subject).to be_fired
  end

  it "allows custom default states" do
    expect(CustomDefaultMachine.new.state).to be :foobar
  end

  it "supports constraints on valid state transitions" do
    subject.transition :pre_done
    expect { subject.transition :another }.to raise_exception ArgumentError
  end

  context "with a dummy actor attached" do
    let(:delay_interval) { CelluloidSpecs::TIMER_QUANTUM * 10 }
    let(:sleep_interval) { delay_interval + CelluloidSpecs::TIMER_QUANTUM * 10 }

    let(:dummy) do
      Class.new do
        include Celluloid
      end.new
    end

    before do
      subject.attach dummy
      subject.transition :another
    end

    context "with a delayed transition" do
      before { subject.transition :done, :delay => delay_interval }

      context "before delay has ended" do
        it "stays unchanged" do
          expect(subject.state).to be :another
        end
      end

      context "when delay has ended" do
        before { sleep sleep_interval }

        it "transitions to delayed state" do
          expect(subject.state).to be :done
        end
      end

      context "when another transition is made meanwhile" do
        before do
          subject.transition :pre_done
          sleep sleep_interval
        end

        it "cancels delayed state transition" do
          expect(subject.state).to be :pre_done
        end
      end
    end
  end

  context "actor is not set" do
    context "transition is delayed" do
      it "raises an unattached error" do
        expect { subject.transition :another, :delay => 100 } \
          .to raise_error(Celluloid::FSM::UnattachedError)
      end
    end
  end

  context "transitioning to an invalid state" do
    it "raises an argument error" do
      expect { subject.transition :invalid_state }.to raise_error(ArgumentError)
    end

    it "should not call transition! if the state is :default" do
      expect(subject).not_to receive :transition!
      subject.transition :default
    end
  end
end
