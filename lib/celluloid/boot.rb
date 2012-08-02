# Things to run after Celluloid is fully loaded

# Configure default systemwide settings
Celluloid.logger     = Logger.new STDERR
Celluloid.task_class = Celluloid::TaskFiber

# Launch the notifications fanout actor
# FIXME: We should set up the supervision hierarchy here
Celluloid::Logger.info "Starting notification manager"
supervisor = Celluloid::Notifications::Fanout.supervise_as :notifications_fanout
Celluloid::Logger.info "Supervised by:   #{supervisor}"
Celluloid::Logger.info "Fanout actor is: #{Celluloid::Actor[:notifications_fanout].inspect}"