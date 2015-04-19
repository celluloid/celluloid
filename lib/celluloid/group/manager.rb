module Celluloid
  class Group
    class Manager

      include Celluloid

      def initialize group
        @group = group
        # every( 1.26 ) { garbage_collector }
      end

      def garbage_collector
        @group.each { |t|
          case t[:celluloid_meta][:state]
          when :finished
            # puts "thread finished: #{t.inspect}"
          else
            # puts "thread state: #{t[:celluloid_meta]}"
          end
          # puts "thread: #{t[:celluloid_actor].name}" 
        }
      rescue => ex
        # puts "#{ex.backtrace.first}"
      end

    end
  end
end
