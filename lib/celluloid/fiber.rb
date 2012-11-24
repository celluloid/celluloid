# Fibers are hard... let's go shopping!
begin
  require 'fiber'
rescue LoadError => ex
  if defined? JRUBY_VERSION
    if RUBY_VERSION < "1.9.2"
      raise LoadError, "Celluloid requires JRuby 1.9 mode. Please pass the --1.9 flag or set JRUBY_OPTS=--1.9"
    end

    # Fibers are broken on JRuby 1.6.5. This works around the issue
    if JRUBY_VERSION[/^1\.6\.5/]
      require 'jruby'
      org.jruby.ext.fiber.FiberExtLibrary.new.load(JRuby.runtime, false)
      class org::jruby::ext::fiber::ThreadFiber
        field_accessor :state
      end

      class Fiber
        def alive?
          JRuby.reference(self).state != org.jruby.ext.fiber.ThreadFiberState::FINISHED
        end
      end
    else
      # Just in case subsequent JRuby releases have broken fibers :/
      raise ex
    end
  elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == "rbx"
    raise LoadError, "Celluloid requires Rubinius 1.9 mode. Please pass the -X19 flag."
  else
    raise ex
  end
end
