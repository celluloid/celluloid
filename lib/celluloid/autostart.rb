require "celluloid"

# start up the basic Celluloid services - only necessary to do this manually in old versions
Celluloid.start

unless defined?($CELLULOID_TEST) && $CELLULOID_TEST
  Celluloid.register_shutdown
  Celluloid.init
end
