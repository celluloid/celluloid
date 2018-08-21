require "celluloid"

Celluloid.boot

# !!! DO NOT INTRODUCE ADDITIONAL GLOBAL VARIABLES !!!
# rubocop:disable Style/GlobalVars
Celluloid.register_shutdown unless defined?($CELLULOID_TEST) && $CELLULOID_TEST
# rubocop:enable Style/GlobalVars
