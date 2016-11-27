module Specs
  class << self
    def logger
      @logger ||= default_logger.tap { |log| log.level = Logger::WARN }
    end

    attr_writer :logger

    private

    def default_logger
      Logger.new(STDERR)
    end

    def open_logfile(rel_path, sync)
      root = Pathname(__FILE__).dirname.dirname.dirname
      log_path = root + rel_path
      log_path.dirname.mkpath
      logfile = File.open(log_path.to_s, "a")
      logfile.sync if sync
      logfile
    end
  end
end
