module Specs
  class << self
    def loose_threads
      Thread.list.map do |thread|
        next unless thread
        next if thread == Thread.current
        if RUBY_PLATFORM == 'java'
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
          next if thread.backtrace.empty?
          next if thread.backtrace.first =~ %r{rubysl/timeout/timeout\.rb}
        end

        if RUBY_ENGINE == "ruby"
          # Sometimes stays
          next if thread.backtrace.first =~ %r{/timeout\.rb}
        end

        thread
      end.compact
    end

    def assert_no_loose_threads(location)
      Specs.assert_no_loose_threads!("before example: #{location}")
      yield
      Specs.assert_no_loose_threads!("after example: #{location}")
    end

    def thread_name(thread)
      (RUBY_PLATFORM == 'java') ? thread.to_java.getNativeThread.get_name : ""
    end

    def assert_no_loose_threads!(location)
      loose = Specs.loose_threads
      backtraces = loose.map do |th|
        name = thread_name(thread)
        description = "#{th.inspect}#{name.empty? ? '' : "(#{name})"}"
        "Runaway thread: ================ #{description}\n" \
          "Backtrace: \n ** #{th.backtrace * "\n ** "}\n"
      end

      return if loose.empty?

      if RUBY_PLATFORM == 'java' && !Nenv.ci?
        STDERR.puts "Aborted due to runaway threads (#{location})\n"\
          "List: (#{loose.map(&:inspect)})\n:#{backtraces.join("\n")}"

        STDERR.puts "Sleeping so you can investigate on the Java side...."
        sleep
      end

      fail "Aborted due to runaway threads (#{location})\n"\
        "List: (#{loose.map(&:inspect)})\n:#{backtraces.join("\n")}"
    end
  end
end
