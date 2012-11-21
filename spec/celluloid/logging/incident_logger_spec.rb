require 'spec_helper'

describe Celluloid::IncidentLogger do
  let(:logger) { Celluloid::IncidentLogger.new }

  let(:test_reporter) { Celluloid::Actor[:test_incident_reporter] }

  before(:each) do
    test_reporter.clear_incidents
  end

  # not sure how to include modules in rspec tests...
  TRACE   = Celluloid::IncidentLogger::Severity::TRACE
  DEBUG   = Celluloid::IncidentLogger::Severity::DEBUG
  INFO    = Celluloid::IncidentLogger::Severity::INFO
  WARN    = Celluloid::IncidentLogger::Severity::WARN
  ERROR   = Celluloid::IncidentLogger::Severity::ERROR
  FATAL   = Celluloid::IncidentLogger::Severity::FATAL
  UNKNOWN = Celluloid::IncidentLogger::Severity::UNKNOWN

  it "should set level" do
    logger.level.should == DEBUG
    [TRACE, DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN].each do |l|
      logger.level = l
      logger.level.should == l
    end
  end

  it "should set threshold" do
    logger.threshold.should == ERROR
    [TRACE, DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN].each do |t|
      logger.threshold = t
      logger.threshold.should == t
    end
  end

  it "should set progname" do
    logger.progname.should == "default"
    logger.progname = "name"
    logger.progname.should == "name"
  end

  it "should initialize with arguments" do
    described_class.new("name").progname.should == "name"
    described_class.new(nil, level: ERROR).level.should == ERROR
    described_class.new(nil, threshold: WARN).threshold.should == WARN
    described_class.new(nil, sizelimit: 20).sizelimit.should == 20
  end

  it "should ignore events below the level" do
    logger.add(TRACE, "trace").should be_nil
    logger.buffer_for(TRACE).should be_empty
  end

  it "should return the event id for events meeting the level" do
    event_id = logger.add(DEBUG, "test message")
    event_id.should_not be_nil
  end

  it "should add events below the threshold to a buffer" do
    logger.add(DEBUG, "test message")
    event = logger.buffer_for(DEBUG).shift
    event.should be_a(Celluloid::LogEvent)
    event.message.should == "test message"
    event.severity.should == DEBUG
    event.progname.should == logger.progname

    logger.add(DEBUG, "test message", "other_progname")
    event = logger.buffer_for("other_progname", DEBUG).shift
    event.progname.should == "other_progname"

    logger.add(DEBUG) { "deferred message" }
    event = logger.buffer_for(DEBUG).shift
    event.message.should == "deferred message"
  end

  it "should flush and report events above the threshold" do
    debug_id = logger.add(DEBUG, "test message")
    error_id = logger.add(ERROR, "test error")
    logger.buffers_for(logger.progname).each do |sev, buffer|
      buffer.should be_empty
    end

    test_reporter.incidents.size.should == 1
    incident = test_reporter.incidents.first

    incident.triggering_event.id = error_id
    incident.events.first.id.should == debug_id
    incident.events.first.message.should == "test message"
    incident.events.last.message.should == "test error"
  end

  it "should define level shortcuts" do
    # log everything, report nothing
    logger = described_class.new(nil, level: TRACE, threshold: UNKNOWN+1)

    logger.trace("trace")
    logger.debug("debug")
    logger.info("info")
    logger.warn("warn")
    logger.error("error")
    logger.fatal("fatal")
    logger.unknown("unknown")
    logger.buffer_for(TRACE).shift.message.should == "trace"
    logger.buffer_for(DEBUG).shift.message.should   == "debug"
    logger.buffer_for(INFO).shift.message.should    == "info"
    logger.buffer_for(WARN).shift.message.should    == "warn"
    logger.buffer_for(ERROR).shift.message.should   == "error"
    logger.buffer_for(FATAL).shift.message.should   == "fatal"
    logger.buffer_for(UNKNOWN).shift.message.should == "unknown"
  end

  it "should take progname for level shortcuts" do
    # log everything, report nothing
    logger = described_class.new(nil, level: TRACE, threshold: UNKNOWN+1)

    logger.trace("other_name")   { "trace" }
    logger.debug("other_name")   { "debug" }
    logger.info("other_name")    { "info"  }
    logger.warn("other_name")    { "warn"  }
    logger.error("other_name")   { "error" }
    logger.fatal("other_name")   { "fatal" }
    logger.unknown("other_name") { "unknown" }
    logger.buffer_for("other_name", TRACE).shift.message.should   == "trace"
    logger.buffer_for("other_name", DEBUG).shift.message.should   == "debug"
    logger.buffer_for("other_name", INFO).shift.message.should    == "info"
    logger.buffer_for("other_name", WARN).shift.message.should    == "warn"
    logger.buffer_for("other_name", ERROR).shift.message.should   == "error"
    logger.buffer_for("other_name", FATAL).shift.message.should   == "fatal"
    logger.buffer_for("other_name", UNKNOWN).shift.message.should == "unknown"
  end

  it "should log to fallback logger if publish fails" do
    logger.fallback_logger.should be_a(::Logger)
    stream = StringIO.new
    logger.fallback_logger = Logger.new(stream)
    begin
      # killing notifier will cause logger to crash
      Celluloid::Notifications.notifier.terminate
      logger.add(ERROR, "test error")
      stream.size.should_not == 0
    ensure
      Celluloid::Notifications::Fanout.supervise_as :notifications_fanout
    end
  end

  it "should cycle buffer when it fills up" do
    logger = described_class.new(nil, sizelimit: 5)
    6.times { |i| logger.debug(i.to_s) }
    logger.buffer_for(DEBUG).shift.message.should == "1"
  end

  it "should publish all events to the firehose" do
    consumer = Celluloid::TestFirehoseConsumer.new
    logger.debug("debug")
    consumer.events.should_not be_empty
    consumer.events.first.message.should == "debug"
    consumer.terminate
  end

  it "should turn off the firehose if directed" do
    consumer = Celluloid::TestFirehoseConsumer.new
    logger = described_class.new(nil, firehose: false)
    logger.debug("debug")
    consumer.events.should be_empty
    consumer.terminate
  end
  #TODO thread safety
end
