module Celluloid
  class StackDump

    class TaskState < Struct.new(:task_class, :status, :backtrace)
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
        if thread.celluloid?
          next unless thread.role == :actor
          @actors << snapshot_actor(thread.actor) if thread.actor
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
        state.tasks = tasks.collect { |t| TaskState.new(t.class, t.status, t.backtrace) }
      end

      state.backtrace = actor.thread.backtrace if actor.thread
      state
    end

    def snapshot_thread(thread)
      ThreadState.new(thread.object_id, thread.backtrace)
    end

    def dump(output = STDERR)
      @actors.each do |actor|
        string = ""
        string << "Celluloid::Actor 0x#{actor.subject_id.to_s(16)}: #{actor.subject_class}"
        string << " [#{actor.name}]" if actor.name
        string << "\n"

        if actor.status == :idle
          string << "State: Idle (waiting for messages)\n"
          display_backtrace actor.backtrace, string
        else
          string << "State: Running (executing tasks)\n"
          display_backtrace actor.backtrace, string
          string << "Tasks:\n"

          actor.tasks.each_with_index do |task, i|
            string << "  #{i+1}) #{task.task_class}: #{task.status}\n"
            display_backtrace task.backtrace, string
          end
        end

        output.print string
      end

      @threads.each do |thread|
        string = ""
        string << "Thread 0x#{thread.thread_id.to_s(16)}:\n"
        display_backtrace thread.backtrace, string
        output.print string
      end
    end

    def display_backtrace(backtrace, output)
      if backtrace
        output << "\t" << backtrace.join("\n\t") << "\n\n"
      else
        output << "EMPTY BACKTRACE\n\n"
      end
    end
  end
end
