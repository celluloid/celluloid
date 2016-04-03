require "celluloid"

Celluloid.start

unless defined?($CELLULOID_TEST) && $CELLULOID_TEST
  Celluloid.register_shutdown
  Celluloid.init
end
