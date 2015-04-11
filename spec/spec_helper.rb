require 'nenv'

require 'dotenv'
Dotenv.load!(Nenv('celluloid').config_file || (Nenv.ci? ? '.env-ci' : '.env-dev'))

module Specs
  def self.sleep_and_wait_until(timeout=10)
    t1 = Time.now.to_f
    ::Timeout.timeout(timeout) do
      loop until yield
    end

    diff = Time.now.to_f - t1
    STDERR.puts "wait took a bit long: #{diff} seconds" if diff > 0.4
  rescue Timeout::Error
    t2 = Time.now.to_f
    fail "Timeout after: #{t2 - t1} seconds"
  end

  def self.env
    @env ||= Nenv('celluloid_specs')
  end

  def self.retry_count_for(metadata)
    Integer(ENV['CELLULOID_SPECS_RETRY_COUNT'])
  rescue
    # TODO: remove the bypass_flaky altogether at some point
    from_env = Specs.env.bypass_flaky? ? 0 : 1
    metadata[:flaky] ? ( Nenv.ci? ? 5 : from_env) : 1
  end

  class << self
    def log
      # Setup ENV variable handling with sane defaults
      @log ||= Nenv('celluloid_specs_log') do |env|
        env.create_method(:file) { |f| f || '../../log/default.log' }
        env.create_method(:sync?) { |s| s || !Nenv.ci? }

        env.create_method(:strategy) do |strategy|
          strategy || (Nenv.ci? ? 'stderr' : 'split')
        end

        env.create_method(:level) do |level|
          begin
            Integer(level)
          rescue
            env.strategy == 'stderr' ? Logger::WARN : Logger::DEBUG
          end
        end
      end
    end

    def split_logs?
      log.strategy == 'split'
    end

    def logger
      @logger ||= default_logger.tap { |logger| logger.level = log.level }
    end

    def logger=(logger)
      @logger = logger
    end

    def default_logger
      case log.strategy
      when 'stderr'
        Logger.new(STDERR)
      when 'single'
        logfile = File.open(File.expand_path(log.file, __FILE__), 'a')
        logfile.sync if log.sync?
        Logger.new(logfile)
      when 'split'
        # Use Celluloid in case there's logging in a before/after handle
        # (is that a bug in rspec-log_split?)
        Celluloid.logger
      else
        fail "Unknown logger strategy: #{strategy.inspect}. Expected 'split', 'single' or 'stderr'."
      end
    end

    def loose_threads
      Thread.list.map do |thread|
        next if thread == Thread.current
        if defined?(JRUBY_VERSION)
          # Avoid disrupting jRuby's "fiber" threads.
          next if /Fiber/ =~ thread.to_java.getNativeThread.get_name
          backtrace = thread.backtrace # avoid race maybe
          next unless backtrace
          next if backtrace.empty? # possibly a timer thread
        end
        if RUBY_ENGINE == "rbx"
          # Avoid disrupting Rubinious thread
          next if thread.backtrace.empty?
          next if thread.backtrace.first =~ /rubysl\/timeout\/timeout.rb/
        end
        thread
      end.compact
    end

    def assert_no_loose_threads!(location)
      loose = Specs.loose_threads
      backtraces = loose.map do |th|
        "Runaway thread: ================ #{th.inspect}\n" +
        "Backtrace: \n ** #{th.backtrace * "\n ** "}\n"
      end
      fail "Aborted due to runaway threads (#{location})\nList: (#{loose.map(&:inspect)})\n:#{backtraces.join("\n")}" unless loose.empty?
    end

    def reset_probe(value)
      return unless Celluloid.const_defined?(:Probe)
      probe = Celluloid::Probe
      const = :INITIAL_EVENTS
      probe.send(:remove_const, const) if probe.const_defined?(const)
      probe.const_set(const, value)
    end
  end
end

if Nenv.ci?
  require 'coveralls'
  Coveralls.wear!
end

require 'rubygems'
require 'bundler/setup'

# Require in order, so both CELLULOID_TEST and CELLULOID_DEBUG are true
require 'celluloid/test'

module CelluloidSpecs
  def self.included_module
    # Celluloid::IO implements this with with 'Celluloid::IO'
    Celluloid
  end

  # Timer accuracy enforced by the tests (50ms)
  TIMER_QUANTUM = 0.05
end

$CELLULOID_DEBUG = true

require 'rspec/log_split' if Specs.split_logs?

Celluloid.shutdown_timeout = 1

Dir['./spec/support/*.rb'].map {|f| require f }

RSpec.configure do |config|
  unless Nenv.ci?
    config.filter_run :focus => true
  end

  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.profile_examples = 3

  if Specs.split_logs?
    config.log_split_dir = File.expand_path("../../log/#{DateTime.now.iso8601}", __FILE__)
    config.log_split_module = Specs
  end

  config.around do |ex|
    Celluloid.actor_system = nil

    Specs.assert_no_loose_threads!("before example: #{ex.description}")

    ex.run

    Specs.assert_no_loose_threads!("after example: #{ex.description}")
  end

  config.around actor_system: :global do |ex|
    # Needed because some specs mock/stub/expect on the logger
    Celluloid.logger = Specs.logger

    Specs.reset_probe(Queue.new)
    Celluloid.boot
    ex.run
    Celluloid.shutdown
    Specs.reset_probe(Queue.new)
  end

  config.around actor_system: :within do |ex|
    Celluloid::ActorSystem.new.within do
      ex.run
    end
  end

  config.filter_gems_from_backtrace(*%w(rspec-expectations rspec-core rspec-mocks rspec-retry rspec-log_split rubysl-thread rubysl-timeout))

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end

  config.around(:each) do |example|
    # Needed because some specs mock/stub/expect on the logger
    Celluloid.logger = Specs.logger

    config.default_retry_count = Specs.retry_count_for(example.metadata)
    example.run
  end

  # Must be *after* the around hook above
  require 'rspec/retry'
  config.verbose_retry = true
  config.default_sleep_interval = 3
end
