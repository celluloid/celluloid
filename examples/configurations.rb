require "celluloid"

puts "Use Supervision::Configuration objects!"

class Hello
  include Celluloid

  finalizer :ceasing

  def initialize(to)
    @to = to
    puts "Created Hello #{@to}"
  end

  def ceasing
    puts "Hello #{@to} go buhbye"
  end
end

class FooBar
  include Celluloid

  finalizer :ceasing

  def initialize(i = 0)
    @i = i
    puts "Created FooBar: #{@i}"
  end

  def ceasing
    puts "FooBar FooBar: #{@i} go buhbye"
  end
end

puts "\nInstantiated in bulk, using #deploy"

config = Celluloid::Supervision::Configuration.define([
                                                        { type: FooBar, as: :foobar },
                                                        { type: Hello, as: :hello, args: ["World"] }
                                                      ])

config.deploy
puts "...shut it down"
config.shutdown

puts "\nInstantiated in bulk, using .deploy"

config = Celluloid::Supervision::Configuration.deploy([
                                                        { type: FooBar, as: :foobar, args: [1] },
                                                        { type: Hello, as: :hello, args: ["World"] }
                                                      ])

puts "...shut it down"
config.shutdown

puts "\nInstantiated two actors individually, using a local configuration object"

config = Celluloid::Supervision::Configuration.new
config.define type: FooBar, as: :foobar11, args: [11]
config.define type: FooBar, as: :foobar33, args: [33]
config.deploy

puts "Instantiated another, which starts automatically."
puts "... using the local configuration object"
puts "... using a lazy loaded argument"
config.add type: Hello, as: :hello, args: -> { "Spinning World" }

config.shutdown

puts "\nReuse our last configuration!"

config.deploy
puts "...shut it down"
config.shutdown

puts "Thinking for 4 seconds, and 4 seconds only."
sleep 4
puts "Use Supervision::Configuration objects. Really!"
