module Celluloid
  module Internals
    class Stack
      attr_accessor :actors, :threads

      def initialize(threads)
        @group = threads
        @actors  = []
        @threads = []
      end

      def snapshot(backtrace=nil)
        @group.each do |thread|
          if thread.role == :actor
            @actors << snapshot_actor(thread.actor, backtrace) if thread.actor
          else
            @threads << snapshot_thread(thread, backtrace)
          end
        end
      end

      def snapshot_actor(actor, backtrace=nil)
        state = ActorState.new
        state.id = actor.object_id

        # TODO: delegate to the behavior
        state.cell = snapshot_cell(actor.behavior) if actor.behavior.is_a?(Cell)

        tasks = actor.tasks
        if tasks.empty?
          state.status = :idle
        else
          state.status = :running
          state.tasks = tasks.to_a.map { |t| TaskState.new(t.class, t.type, t.meta, t.status, t.backtrace) }
        end

        state.backtrace = actor.thread.backtrace if backtrace && actor.thread
        state
      end

      def snapshot_cell(behavior)
        state = CellState.new
        state.subject_id = behavior.subject.object_id
        state.subject_class = behavior.subject.class
        state
      end

      def snapshot_thread(thread, backtrace=nil)
        backtrace = begin
                      thread.backtrace
                    rescue NoMethodError # for Rubinius < 2.5.2.c145
                      []
                    end if backtrace
        ThreadState.new(thread.object_id, backtrace, thread.role)
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
end

require "celluloid/internals/stack/states"
require "celluloid/internals/stack/dump"
require "celluloid/internals/stack/summary"
