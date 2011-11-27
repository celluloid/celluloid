# Every time I look at this code a little part of me dies...
begin
  require 'fiber'
rescue LoadError => ex
  if defined? JRUBY_VERSION
    if RUBY_VERSION < "1.9.2"
      raise LoadError, "Celluloid requires JRuby 1.9 mode. Please pass the --1.9 flag or set JRUBY_OPTS=--1.9"
    end

    # Fibers are broken on JRuby 1.6.5. This works around the issue
    if JRUBY_VERSION == "1.6.5"
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
  elsif defined? Rubinius
    # If we're on Rubinius, we can still work in 1.8 mode
    Fiber = Rubinius::Fiber
  else
    raise ex
  end
end

module Celluloid
  class Fiber < ::Fiber
    def initialize(*args)
      actor   = Thread.current[:actor]
      mailbox = Thread.current[:mailbox]

      super do
        Thread.current[:actor]   = actor
        Thread.current[:mailbox] = mailbox

        yield(*args)
      end
    end

    def resume(value = nil)
      result = super
      actor = Thread.current[:actor]
      return result unless actor

      if result.is_a? Celluloid::Call
        actor.register_fiber result, self
      elsif result
        warning = "non-call returned from fiber: #{result.class}"
        Celluloid.logger.debug warning if Celluloid.logger
      end
      nil
    end
  end
end
