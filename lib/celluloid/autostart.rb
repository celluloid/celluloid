require "celluloid"

# !!! DO NOT INTRODUCE ADDITIONAL GLOBAL VARIABLES !!!
# rubocop:disable Style/GlobalVars

Celluloid.boot
Celluloid.register_shutdown unless defined?($CELLULOID_TEST) && $CELLULOID_TEST
