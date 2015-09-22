require "nenv"
require "dotenv"

Dotenv.load!(Nenv("celluloid").config_file || (Nenv.ci? ? ".env-ci" : ".env-dev"))

if Nenv.ci?
  require "coveralls"
  Coveralls.wear!
end

require "rubygems"
require "bundler/setup"

# Require in order, so both CELLULOID_TEST and CELLULOID_DEBUG are true
require "celluloid/rspec"
require "celluloid/supervision"

module Specs

  def self.env
    @env ||= Nenv("celluloid_specs")
  end

  class << self
    def log
      # Setup ENV variable handling with sane defaults
      @log ||= Nenv("celluloid_specs_log") do |env|
        env.create_method(:file) { |f| f || "../../log/default.log" }
        env.create_method(:sync?) { |s| s || !Nenv.ci? }

        env.create_method(:strategy) do |strategy|
          strategy || (Nenv.ci? ? "stderr" : "single")
        end

        env.create_method(:level) do |level|
          begin
            Integer(level)
          rescue
            env.strategy == "stderr" ? Logger::WARN : Logger::DEBUG
          end
        end
      end
    end

    def logger
      @logger ||= default_logger.tap { |logger| logger.level = log.level }
    end

    attr_writer :logger

    def default_logger
      case log.strategy
      when "stderr"
        Logger.new(STDERR)
      when "single"
        logfile = File.open(File.expand_path(log.file, __FILE__), "a")
        logfile.sync if log.sync?
        Logger.new(logfile)
      else
        fail "Unknown logger strategy: #{strategy.inspect}. Expected 'single' or 'stderr'."
      end
    end

    def loose_threads
      Thread.list.map do |thread|
        next if thread == Thread.current
        if RUBY_PLATFORM == "java"
          # Avoid disrupting jRuby's "fiber" threads.
          next if /Fiber/ =~ thread.to_java.getNativeThread.get_name
          backtrace = thread.backtrace # avoid race maybe
          next unless backtrace
          next if backtrace.empty? # possibly a timer thread
        elsif RUBY_ENGINE == "rbx"
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
        "Runaway thread: ================ #{th.inspect}\n" \
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

$CELLULOID_DEBUG = true

Celluloid.shutdown_timeout = 1

Dir["./spec/support/*/*.rb"].map { |f| require f }

RSpec.configure do |config|
  config.filter_run focus: true unless Nenv.ci?

  config.backtrace_exclusion_patterns = [
    /spec_helper/,
    /bin/,
  ]

  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.profile_examples = 3

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
    Celluloid::Actor::System.new.within do
      ex.run
    end
  end

  config.filter_gems_from_backtrace(*%w(rspec-expectations rspec-core rspec-mocks rspec-retry rubysl-thread rubysl-timeout))

  config.mock_with :rspec do |mocks|
    mocks.verify_doubled_constant_names = true
    mocks.verify_partial_doubles = true
  end

  config.around(:each) do |example|
    # Needed because some specs mock/stub/expect on the logger
    Celluloid.logger = Specs.logger
    example.run
  end
end
