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
        output << "\n"

        tasks = actor.tasks
        if tasks.empty?
          output << "State: Idle (waiting for messages)\n"
        else
          output << "State: Running (executing tasks)\n"
          output << "Tasks:\n"

          tasks.each_with_index do |task, i|
            output << "  #{i+1}) #{task.class}: #{task.status}\n"
          end
        end

        display_backtrace actor.thread, output
      end

      threads.each do |thread|
        output << "Thread 0x#{object_id.to_s(16)}:\n"
        display_backtrace thread, output
      end
    end

    def self.display_backtrace(thread, output)
      output << "\t" << thread.backtrace.join("\n\t") << "\n\n"
    end
  end
end
