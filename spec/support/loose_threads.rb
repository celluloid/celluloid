module Specs
  class << self
    def loose_threads
      Thread.list.map do |thread|
        next unless thread
        next if thread == Thread.current

        if RUBY_PLATFORM == "java"
          # Avoid disrupting jRuby's "fiber" threads.
          name = thread.to_java.getNativeThread.get_name
          next if /Fiber/ =~ name
          next unless /^Ruby-/ =~ name
          backtrace = thread.backtrace # avoid race maybe
          next unless backtrace
          next if backtrace.empty? # possibly a timer thread
        end

        if RUBY_ENGINE == "rbx"
          # Avoid disrupting Rubinious thread
          next if thread.backtrace.first =~ %r{rubysl/timeout/timeout\.rb}

          if Specs::ALLOW_SLOW_MAILBOXES
            if thread.backtrace.first =~ /wait/
              next if thread.backtrace[1] =~ /mailbox\.rb/ && thread.backtrace[1] =~ /check/
            end
          end
        end

        if RUBY_ENGINE == "ruby"
          # Sometimes stays
          next if thread.backtrace.nil?
          next unless thread.backtrace.is_a?(Array)
          next if thread.backtrace.empty?
          next if thread.backtrace.first =~ /timeout\.rb/
        end

        thread
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

      fail Celluloid::ThreadLeak, "Aborted due to runaway threads (#{location})\n"\
        "List: (#{loose.map(&:inspect)})\n:#{backtraces.join("\n")}"
    end
  end
end
