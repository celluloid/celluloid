# TODO: Remove at 0.19.0
module Celluloid
  SupervisionGroup = Supervision::Container
  Supervision::Group = Supervision::Container
  Supervision::Member = Supervision::Container::Instance
end

require "celluloid/supervision/deprecate/supervise"
require "celluloid/supervision/deprecate/validation"
