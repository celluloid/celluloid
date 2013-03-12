# Things to run after Celluloid is fully loaded

# Configure default systemwide settings
if defined? JRUBY_VERSION
  Celluloid.task_class = Celluloid::TaskThread
else
  Celluloid.task_class = Celluloid::TaskFiber
end

Celluloid.logger     = Logger.new(STDERR)

# Launch default services
# FIXME: We should set up the supervision hierarchy here
Celluloid::Notifications::Fanout.supervise_as :notifications_fanout
Celluloid::IncidentReporter.supervise_as :default_incident_reporter, STDERR

# Terminate all actors at exit
at_exit do
  if defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby" && RUBY_VERSION >= "1.9"
    # workaround for MRI bug losing exit status in at_exit block
    # http://bugs.ruby-lang.org/issues/5218
    exit_status = $!.status if $!.is_a?(SystemExit)
    Celluloid.shutdown
    exit exit_status if exit_status
  else
    Celluloid.shutdown
  end
end
