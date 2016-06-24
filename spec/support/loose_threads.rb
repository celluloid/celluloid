module Specs
  class << self
    def loose_threads
      Thread.list.map do |thread|
        begin
          next unless thread && thread.celluloid?
        rescue
          thread
        end
      end.compact
    end

    def thread_name(thread)
      (RUBY_PLATFORM == "java") ? thread.to_java.getNativeThread.get_name : ""
    end

    def assert_no_loose_threads!(location)
      loose = Specs.loose_threads
      backtraces = loose.map do |thread|
        name = thread_name(thread)
        description = "#{thread.inspect}#{name.empty? ? '' : "(#{name})"}"
        "Runaway thread: ================ #{description}\n" \
          "Backtrace: \n ** #{thread.backtrace * "\n ** "}\n"
      end

      return if loose.empty?

      if RUBY_PLATFORM == "java" && !Nenv.ci?
        STDERR.puts "Aborted due to runaway threads (#{location})\n"\
          "List: (#{loose.map(&:inspect)})\n:#{backtraces.join("\n")}"

        STDERR.puts "Sleeping so you can investigate on the Java side...."
        sleep
      end

      raise Celluloid::ThreadLeak, "Aborted due to runaway threads (#{location})\n"\
        "List: (#{loose.map(&:inspect)})\n:#{backtraces.join("\n")}"
    end
  end
end
