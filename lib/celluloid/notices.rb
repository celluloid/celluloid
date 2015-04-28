module Celluloid
  module Notices
    class << self

      @@notices = []

      def backported_mini
        @@notices << [ :warn, "Celluloid is running in BACKPORTED mode. [ http://git.io/vfteb ]" ]
      end

      def backported
        @@notices << [ :warn, "+--------------------------------------------------+" ]
        @@notices << [ :warn, "|     Celluloid is running in BACKPORTED mode.     |" ]
        @@notices << [ :warn, "|   Time to update deprecated code, before v1.0!   |" ]
        @@notices << [ :warn, "+--------------------------------------------------+" ]
        @@notices << [ :warn, "|  Prepare! As of v0.17.5 you can begin updating.  |" ]
        @@notices << [ :warn, "+--------------------------------------------------+" ]
        @@notices << [ :warn, "|    Want to read about it? http://git.io/vfteb    |" ]
        @@notices << [ :warn, "+--------------------------------------------------+" ]
      end

      def output
        @@notices.each { |type,notice| Celluloid::Internals::Logger.send type, notice }
      end

    end
  end
end
