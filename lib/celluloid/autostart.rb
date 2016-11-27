require "celluloid"

Celluloid.boot
Celluloid.register_shutdown unless defined?($CELLULOID_TEST) && $CELLULOID_TEST
