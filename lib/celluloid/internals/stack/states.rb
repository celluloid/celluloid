module Celluloid
  module Internals
    class Stack

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

      class TaskState < Struct.new(:task_class, :type, :meta, :status, :backtrace); end

      class CellState < Struct.new(:subject_id, :subject_class)
        def dump
          "Celluloid::Cell 0x#{subject_id.to_s(16)}: #{subject_class}"
        end
      end

      class ThreadState < Struct.new(:thread_id, :backtrace, :role)
        include DisplayBacktrace
      end

      class ActorState
        include DisplayBacktrace
        attr_accessor :name, :id, :cell
        attr_accessor :status, :tasks
        attr_accessor :backtrace
      end

    end
  end
end
