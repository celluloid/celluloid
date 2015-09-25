RSpec.configure do |config|
  config.filter_run focus: true unless Nenv.ci?

  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.profile_examples = 3

  config.before(:suite) do
    Specs.stub_out_class_method(Celluloid::Internals::Logger, :crash) do |*args|
      _name, ex = *args
      fail "Unstubbed Logger.crash() was called:\n  crash(\n    #{args.map(&:inspect).join(",\n    ")})"\
        "\nException backtrace: \n  (#{ex.class}) #{ex.backtrace * "\n  (#{ex.class}) "}"
    end
  end

  config.before(:each) do |example|
    @fake_logger = Specs::FakeLogger.new(Celluloid.logger, example.description)
    stub_const("Celluloid::Internals::Logger", @fake_logger)
  end

  config.around do |ex|
    Timeout.timeout(Specs::MAX_EXECUTION) { ex.run }
    if @fake_logger.crashes?
      crashes = @fake_logger.crashes.map do |args, call_stack|
        msg, ex = *args
        "\n** Crash: #{msg.inspect}(#{ex.inspect})\n  Backtrace:\n    (crash) #{call_stack * "\n    (crash) " }"\
          "\n  Exception Backtrace (#{ex.inspect}):\n    (ex) #{ex.backtrace * "\n    (ex) "}"
      end.join("\n")
      fail "Actor crashes occured (please stub/mock if these are expected): #{crashes}"
    end
    @fake_logger = nil
  end

  config.around do |ex|
    Celluloid.actor_system = nil

    Specs.assert_no_loose_threads(ex.description) do
      Specs.reset_class_variables(ex.description) do
        Timeout.timeout(Specs::MAX_EXECUTION) { ex.run }
      end
    end
  end

  config.around actor_system: :io do |ex|
    # Needed because some specs mock/stub/expect on the logger
    Celluloid.logger = Specs.logger
    Celluloid.shutdown
    Celluloid.boot
    FileUtils.rm("/tmp/cell_sock") if File.exist?("/tmp/cell_sock")
    Timeout.timeout(Specs::MAX_EXECUTION) { ex.run }
  end

  config.around actor_system: :global do |ex|
    # Needed because some specs mock/stub/expect on the logger
    Celluloid.logger = Specs.logger
    Celluloid.boot
    Timeout.timeout(Specs::MAX_EXECUTION) { ex.run }
    Celluloid.shutdown
  end

  config.around actor_system: :within do |ex|
    Celluloid::Actor::System.new.within do
      Timeout.timeout(Specs::MAX_EXECUTION) { ex.run }
    end
  end

  config.filter_gems_from_backtrace(*Specs::BACKTRACE_OMITTED)

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end

  config.around(:each) do |ex|
    # Needed because some specs mock/stub/expect on the logger
    Celluloid.logger = Specs.logger
    Timeout.timeout(Specs::MAX_EXECUTION) { ex.run }
  end
end
