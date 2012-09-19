module Celluloid
  module StackDumper
    def self.dump(output = STDERR)
      actors  = {}
      threads = []

      Thread.list.each do |thread|
        if actor = thread[:actor]
          actors[actor.subject.object_id] = actor
        else
          threads << thread
        end
      end

      actors.each do |_, actor|
        output << "Celluloid::Actor 0x#{actor.subject.object_id.to_s(16)}: #{actor.subject.class}"
        output << " [#{actor.name}]" if actor.name

        display_backtrace actor.thread, output
      end

      threads.each do |thread|
        output << "Thread 0x#{object_id.to_s(16)}:"
        display_backtrace thread, output
      end
    end

    def self.display_backtrace(thread, output)
      output << "\n\t" << thread.backtrace.join("\n\t") << "\n\n"
    end
  end
end
