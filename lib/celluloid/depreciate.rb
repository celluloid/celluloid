# TODO: Remove link to Interal::Logger
module Celluloid
  Logger = Internals::Logger
end

Celluloid.logger.warn "+--------------------------------------------------+"
Celluloid.logger.warn "|     Celluloid is running in BACKPORTED mode.     |"
Celluloid.logger.warn "|   Time to update depreciated code before v1.0!   |"
Celluloid.logger.warn "+--------------------------------------------------+"
Celluloid.logger.warn "|  Prepare! As of v0.17.5 you can begin updating.  |"
Celluloid.logger.warn "+--------------------------------------------------+"
Celluloid.logger.warn "|    Want to read about it? http://git.io/vfteb    |"
Celluloid.logger.warn "+--------------------------------------------------+"