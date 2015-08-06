module Celluloid
  module Notices
    class << self
      @@notices = []

      def backported
        @@notices << [:info, "Celluloid #{Celluloid::VERSION} is running in BACKPORTED mode. [ http://git.io/vJf3J ]"]
      end

      def output
        @@notices.each { |type, notice| Celluloid::Internals::Logger.send type, notice }
      end
    end
  end
end
