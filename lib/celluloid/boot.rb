# Things to run after Celluloid is fully loaded

# Configure default systemwide settings
Celluloid.logger     = Logger.new STDERR
Celluloid.task_class = Celluloid::TaskFiber

# Launch the notifications fanout actor
# FIXME: We should set up the supervision hierarchy here
Celluloid::Notifications::Fanout.supervise_as :notifications_fanout