module Celluloid
  class StackDump
    module DisplayBacktrace
      def display_backtrace(backtrace, output, indent = nil)
        backtrace ||= ["EMPTY BACKTRACE"]
        backtrace.each do |line|
          output << indent if indent
          output << "\t" << line << "\n"
        end
        output << "\n\n"
      end
    end

    class TaskState < Struct.new(:task_class, :type, :meta, :status, :backtrace)
    end

    class ActorState
      include DisplayBacktrace
      attr_accessor :name, :id, :cell
      attr_accessor :status, :tasks
      attr_accessor :backtrace

      def dump
        string = ""
        string << "Celluloid::Actor 0x#{id.to_s(16)}"
        string << " [#{name}]" if name
        string << "\n"

        if cell
          string << cell.dump
          string << "\n"
        end

        if status == :idle
          string << "State: Idle (waiting for messages)\n"
          display_backtrace backtrace, string
        else
          string << "State: Running (executing tasks)\n"
          display_backtrace backtrace, string
          string << "\tTasks:\n"

          tasks.each_with_index do |task, i|
            string << "\t  #{i+1}) #{task.task_class}[#{task.type}]: #{task.status}\n"
            string << "\t      #{task.meta.inspect}\n"
            display_backtrace task.backtrace, string, "\t"
          end
        end

        string
      end
    end

    class CellState < Struct.new(:subject_id, :subject_class)
      def dump
        "Celluloid::Cell 0x#{subject_id.to_s(16)}: #{subject_class}"
      end
    end

    class ThreadState < Struct.new(:thread_id, :backtrace, :role)
      include DisplayBacktrace

      def dump
        string = ""
        string << "Thread 0x#{thread_id.to_s(16)} (#{role}):\n"
        display_backtrace backtrace, string
        string
      end
    end

    attr_accessor :actors, :threads

    def initialize(internal_pool)
      @internal_pool = internal_pool

      @actors  = []
      @threads = []

      snapshot
    end

    def snapshot
      @internal_pool.each do |thread|
        if thread.role == :actor
          @actors << snapshot_actor(thread.actor) if thread.actor
        else
          @threads << snapshot_thread(thread)
        end
      end
    end

    def snapshot_actor(actor)
      state = ActorState.new
      state.id = actor.object_id

      # TODO: delegate to the behavior
      if actor.behavior.is_a?(Cell)
        state.cell = snapshot_cell(actor.behavior)
      end

      tasks = actor.tasks
      if tasks.empty?
        state.status = :idle
      else
        state.status = :running
        state.tasks = tasks.to_a.map { |t| TaskState.new(t.class, t.type, t.meta, t.status, t.backtrace) }
      end

      state.backtrace = actor.thread.backtrace if actor.thread
      state
    end

    def snapshot_cell(behavior)
      state = CellState.new
      state.subject_id = behavior.subject.object_id
      state.subject_class = behavior.subject.class
      state
    end

    def snapshot_thread(thread)
      ThreadState.new(thread.object_id, thread.backtrace, thread.role)
    end

    def print(output = STDERR)
      @actors.each do |actor|
        output.print actor.dump
      end

      @threads.each do |thread|
        output.print thread.dump
      end
    end
  end
end
