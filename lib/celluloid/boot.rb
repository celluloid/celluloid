# Things to run after Celluloid is fully loaded

# Configure default systemwide settings
Celluloid.task_class = Celluloid::TaskFiber

# Launch the notifications fanout actor
# FIXME: We should set up the supervision hierarchy here
Celluloid::Notifications::Fanout.supervise_as :notifications_fanout

Celluloid.logger = Celluloid::IncidentLogger.new
Celluloid::IncidentReporter.supervise_as :default_incident_reporter, STDERR
