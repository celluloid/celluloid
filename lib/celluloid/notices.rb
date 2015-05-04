module Celluloid
  module Notices
    class << self
      @@notices = []

      def backported_mini
        @@notices << [:warn, "Celluloid is running in BACKPORTED mode. [ http://git.io/vJf3J ]"]
      end

      def version
        @@notices << [:info, "+--------------------------------------------------+"]
        @@notices << [:info, "|    Celluloid version running now: #{'%-13s' % Celluloid::VERSION}  +"]
      end

      def backported
        version
        @@notices << [:warn, "+--------------------------------------------------+"]
        @@notices << [:warn, "|     Celluloid is running in BACKPORTED mode.     |"]
        @@notices << [:warn, "|   Time to update deprecated code, before v1.0!   |"]
        @@notices << [:warn, "+--------------------------------------------------+"]
        @@notices << [:warn, "|  Prepare! As of v0.17.5 you can begin updating.  |"]
        @@notices << [:warn, "+--------------------------------------------------+"]
        @@notices << [:warn, "|    Want to read about it? http://git.io/vJf3J    |"]
        @@notices << [:warn, "+--------------------------------------------------+"]
      end

      def output
        @@notices.each { |type, notice| Celluloid::Internals::Logger.send type, notice }
      end
    end
  end
end
