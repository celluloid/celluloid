module Celluloid
  class StackDump

    class TaskState < Struct.new(:task_class, :status)
    end

    class ActorState
      attr_accessor :subject_id, :subject_class, :name
      attr_accessor :status, :tasks
      attr_accessor :backtrace
    end

    class ThreadState < Struct.new(:thread_id, :backtrace)
    end

    attr_accessor :actors, :threads

    def initialize
      @actors  = []
      @threads = []

      snapshot
    end

    def snapshot
      Thread.list.each do |thread|
        if actor = thread[:celluloid_actor]
          @actors << snapshot_actor(actor)
        else
          @threads << snapshot_thread(thread)
        end
      end
    end

    def snapshot_actor(actor)
      state = ActorState.new
      state.subject_id = actor.subject.object_id
      state.subject_class = actor.subject.class

      tasks = actor.tasks
      if tasks.empty?
        state.status = :idle
      else
        state.status = :running
        state.tasks = tasks.collect { |t| TaskState.new(t.class, t.status) }
      end

      state.backtrace = actor.thread.backtrace if actor.thread
      state
    end

    def snapshot_thread(thread)
      ThreadState.new(thread.object_id, thread.backtrace)
    end

    def dump(output = STDERR)
      @actors.each do |actor|
        output << "Celluloid::Actor 0x#{actor.subject_id.to_s(16)}: #{actor.subject_class}"
        output << " [#{actor.name}]" if actor.name
        output << "\n"

        if actor.status == :idle
          output << "State: Idle (waiting for messages)\n"
        else
          output << "State: Running (executing tasks)\n"
          output << "Tasks:\n"

          actor.tasks.each_with_index do |task, i|
            output << "  #{i+1}) #{task.task_class}: #{task.status}\n"
          end
        end

        display_backtrace actor.backtrace, output
      end

      @threads.each do |thread|
        output << "Thread 0x#{thread.thread_id.to_s(16)}:\n"
        display_backtrace thread.backtrace, output
      end
    end

    def display_backtrace(backtrace, output)
      output << "\t" << backtrace.join("\n\t") << "\n\n"
    end
  end
end
