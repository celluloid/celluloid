# Things to run after Celluloid is fully loaded

# Configure default systemwide settings
Celluloid.task_class = Celluloid::TaskFiber
Celluloid.logger     = Logger.new(STDERR)
Celluloid.shutdown_timeout = 10

Celluloid.boot

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
