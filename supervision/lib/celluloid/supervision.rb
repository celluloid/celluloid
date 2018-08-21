require "celluloid" unless defined? Celluloid

require "celluloid/supervision/constants"
require "celluloid/supervision/supervise"

require "celluloid/supervision/container"
require "celluloid/supervision/container/instance"
require "celluloid/supervision/container/behavior"
require "celluloid/supervision/container/injections"

require "celluloid/supervision/container/behavior/tree"

require "celluloid/supervision/validation"
require "celluloid/supervision/configuration"
require "celluloid/supervision/configuration/instance"

require "celluloid/supervision/service"

require "celluloid/supervision/deprecate" unless $CELLULOID_BACKPORTED == false
