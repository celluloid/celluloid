raise NotImplementedError, <<-MSG.strip.gsub(/\s+/, " ")
  Celluloid 0.18 no-longer supports the "managed" API.
  Please switch to using: `require 'celluloid'`
  For more information, see:
  https://github.com/celluloid/celluloid/wiki/0.18-API-changes
MSG
