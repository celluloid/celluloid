RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.profile_examples = 3
  config.filter_gems_from_backtrace(*Specs::BACKTRACE_OMITTED)

  config.verbose_retry = true
  config.default_retry_count = Specs::ALLOW_RETRIES
  config.display_try_failure_messages = true
  config.default_sleep_interval = 1
  config.exceptions_to_retry = [Timeout::Error, Celluloid::ThreadLeak]

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end

  config.before(:suite) do
    Specs.stub_out_class_method(Celluloid::Internals::Logger, :crash) do |*args|
      _name, ex = *args
      raise "Unstubbed Logger.crash() was called:\n  crash(\n    #{args.map(&:inspect).join(",\n    ")})"\
        "\nException backtrace: \n  (#{ex.class}) #{ex.backtrace * "\n  (#{ex.class}) "}"
    end
  end

  config.before(:each) do |example|
    @fake_logger = Specs::FakeLogger.new(Celluloid.logger, example.description)
    stub_const("Celluloid::Internals::Logger", @fake_logger)
  end

  config.around do |ex|
    # Needed because some specs mock/stub/expect on the logger
    Celluloid.logger = Specs.logger
    Celluloid.actor_system = nil
    Specs.reset_class_variables(ex.description) do
      Timeout.timeout(Specs::MAX_EXECUTION) { ex.run }
    end
    if @fake_logger.crashes?
      crashes = @fake_logger.crashes.map do |args, call_stack|
        msg, ex = *args
        "\n** Crash: #{msg.inspect}(#{ex.inspect})\n  Backtrace:\n    (crash) #{call_stack * "\n    (crash) "}"\
          "\n  Exception Backtrace (#{ex.inspect}):\n    (ex) #{ex.backtrace * "\n    (ex) "}"
      end.join("\n")
      raise "Actor crashes occurred (please stub/mock if these are expected): #{crashes}"
    end
    @fake_logger = nil
    Specs.assert_no_loose_threads!("after example: #{ex.description}") if Specs::CHECK_LOOSE_THREADS
  end

  config.around :each, library: :IO do |ex|
    Celluloid.init
    FileUtils.rm("/tmp/cell_sock") if File.exist?("/tmp/cell_sock")
    ex.run
    Celluloid.shutdown
  end

  config.around :each, library: :ZMQ do |ex|
    Celluloid::ZMQ.init(1) unless ex.metadata[:no_init]
    Celluloid.boot
    ex.run
    Celluloid.shutdown
    Celluloid::ZMQ.terminate
  end

  config.around :each, actor_system: :global do |ex|
    Celluloid.boot
    ex.run
    Celluloid.shutdown
  end

  config.around :each, actor_system: :within do |ex|
    Celluloid::Actor::System.new.within do
      ex.run
    end
  end
end
