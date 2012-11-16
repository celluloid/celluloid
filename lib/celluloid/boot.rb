# Things to run after Celluloid is fully loaded
module Celluloid
  module_function
  
  def start
    unless @started
      # Configure default systemwide settings
      Celluloid.task_class = Celluloid::TaskFiber
      Celluloid.logger     = ::Logger.new(STDERR)
      
      # Launch default services
      # FIXME: We should set up the supervision hierarchy here
      Celluloid::Notifications::Fanout.supervise_as :notifications_fanout
      Celluloid::IncidentReporter.supervise_as :default_incident_reporter, STDERR
      @started = true
    end
  end
end


unless defined?(CELLULOID_DISABLE_AUTOSTART)
  Celluloid.start()
end
