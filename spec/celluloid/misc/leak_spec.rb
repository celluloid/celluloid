require 'weakref'
require 'objspace'

RSpec.describe "Leaks", actor_system: :global,
               skip: !ENV['CELLULOID_LEAKTEST'] && 'leak test disabled' do
  class LeakActor
    include Celluloid

    def initialize(arg)
      @arg = arg
    end

    def call(arg)
      []
    end

    def terminate
    end
  end

  def wait_for_release(weak, what, count=1000)
    trash = []
    count.times do |step|
      GC.start
      return true unless weak.weakref_alive?
      trash << '*' * step
    end

    dump_base = ENV['CELLULOID_LEAKTEST_DUMP_BASE']
    if dump_base
      ::FileUtils.mkdir_p dump_base
      path = ::File.join(dump_base, what)
      ::File.open("#{path}.json", "w") do |f|
        ::ObjectSpace.dump(weak.__getobj__, output: f)
      end
      ::File.open("#{path}-all.json", "w") do |f|
        ::ObjectSpace.dump_all(output: f)
      end
    end

    false
  end

  def do_actor(what)
    actor = LeakActor.new what
    weak = yield actor
    actor.terminate
    actor = nil
    weak
  end

  def actor_life(what, &block)
    GC.start
    dump_base = ENV['CELLULOID_LEAKTEST_DUMP_BASE']
    ::ObjectSpace.trace_object_allocations_debug_start if dump_base
    weak = do_actor what, &block
    expect(wait_for_release(weak, what)).to be true
    ::ObjectSpace.trace_object_allocations_stop if dump_base
  end

  context 'celluloid actor' do
    it 'is properly destroyed upon termination' do
      actor_life('actor') do |actor|
        WeakRef.new actor
      end
    end
  end

  context 'celluloid actor call' do
    it 'does not hold a reference its arguments on completion' do
      actor_life('call-arg') do |actor|
        arg = []
        actor.call arg
        weak = WeakRef.new arg
        arg = nil
        weak
      end
    end

    it 'does not hold a reference to the return value' do
      actor_life('call-result') do |actor|
        result = actor.call nil
        weak = WeakRef.new result
        result = nil
        weak
      end
    end
  end
end
