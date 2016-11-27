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
        def dump
          string = ""
          string << "Thread 0x#{thread_id.to_s(16)} (#{role}):\n"
          display_backtrace backtrace, string if backtrace
          string
        end
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
            display_backtrace backtrace, string if backtrace
          else
            string << "State: Running (executing tasks)\n"
            display_backtrace backtrace, string if backtrace
            string << "\tTasks:\n"

            tasks.each_with_index do |task, i|
              string << "\t  #{i + 1}) #{task.task_class}[#{task.type}]: #{task.status}\n"
              if task.backtrace
                string << "\t      #{task.meta.inspect}\n"
                display_backtrace task.backtrace, string, "\t"
              end
            end
          end
          string << "\n" unless backtrace
          string
        end
      end
    end
  end
end
