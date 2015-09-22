module Specs
  class << self
    def log
      # Setup ENV variable handling with sane defaults
      @log ||= Nenv("celluloid_specs_log") do |env|
        env.create_method(:file) { |f| f || "log/default.log" }
        env.create_method(:sync?) { |s| s || !Nenv.ci? }

        env.create_method(:strategy) do |strategy|
          strategy || default_strategy
        end

        env.create_method(:level) { |level| default_level_for(env, level) }
      end
    end

    def logger
      @logger ||= default_logger.tap { |logger| logger.level = log.level }
    end

    attr_writer :logger

    private

    def default_logger
      case log.strategy
      when "stderr"
        Logger.new(STDERR)
      when "single"
        Logger.new(open_logfile(log.file, log.sync?))
      else
        fail "Unknown logger strategy: #{strategy.inspect}."\
          " Expected 'single' or 'stderr'."
      end
    end

    def open_logfile(rel_path, sync)
      root = Pathname(__FILE__).dirname.dirname.dirname
      log_path = root + rel_path
      logfile = File.open(log_path.to_s, "a")
      logfile.sync if sync
      logfile
    end

    def default_strategy
      (Nenv.ci? ? "stderr" : "single")
    end

    def default_level_for(env, level)
      Integer(level)
    rescue
      env.strategy == "stderr" ? Logger::WARN : Logger::DEBUG
    end
  end
end
