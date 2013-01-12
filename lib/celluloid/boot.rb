# Things to run after Celluloid is fully loaded

# Configure default systemwide settings
Celluloid.task_class = Celluloid::TaskFiber
Celluloid.logger     = Logger.new(STDERR)

# Launch default services
# FIXME: We should set up the supervision hierarchy here
Celluloid::Notifications::Fanout.supervise_as :notifications_fanout
