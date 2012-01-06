#!/usr/bin/env ruby

$:.push File.expand_path('../../lib', __FILE__)
require 'celluloid'

#
# THE CIGARETTE SMOKERS PROBLEM
# See http://en.wikipedia.org/wiki/Cigarette_smokers_problem
#
# Three smokers are sitting at a table. One is a tobacco grower, the second a
# papermaker, and the third a matchstick maker. They have all brought with
# them an abundance of their own fare, and they're here to smoke! However, in
# order to smoke each man will need the goods of the other two.
#
# After a great deal of disagreement about the best way to settle the three-way
# exchange needed for any one man to enjoy a cigarette, the three men
# eventually negotiate a rather unusual arrangement. Whenever the table in
# front of them is empty they notify the waitress, who selects two of the men
# at random, taking a single unit of their particular good. She then places
# their goods on the table and gives a wink and a nod to the third man.
#
# If the third man whose goods she did not take is not smoking, he'll take
# the two items and use his own supply of the third to enjoy a cigarette.
# If, however, he's already smoking, he'll smile and nod in return, perhaps
# taking an extra long drag on his cigarette, possibly to the chagrin of his
# compatriates. For you see, the rules are that only the third man in this
# exchange is allowed to remove the items from the table. If he's already
# enjoying a cigarette, the other two are forced to wait.
#
# One way or another, the third man will eventually collect the items from the
# table. When he does, he'll whistle for the waitress, and she'll again select
# two men at random, replenishing the table.

class Tobacco
  def burn
    carcinogens = [:polonium, :nitrosamine, :benzopyrene]
    [:nicotine, *carcinogens]
  end
end

class Paper
  def roll(tobacco)
    Cigarette.new(tobacco, self)
  end
  def burn; [:ash]; end
end

class Matches
  def initialize
    @lit = false
  end

  def light; @lit = true; end
  def lit?; @lit; end
end

class Cigarette
  def initialize(tobacco, paper)
    @lit = false
    @tobacco, @paper = tobacco, paper
  end

  def light(match)
    @lit = true if match.lit?
  end

  def lit?; @lit end

  def smoke
    raise "not lit" unless @lit
    @tobacco.burn + @paper.burn
  end
end

# Each of the three men at the table is a smoker
class Smoker
  include Celluloid::FSM

  default_state :standing

  state :waiting, :to => :procuring do
    if @table.empty?
      puts "#{name} whistles at waitress... get me smokes!"
      @table.waitress.whistle! # We'll decide what to do when the waitress arrives
    end
  end

  state :procuring, :to => [:waiting, :smoking] do
    if take_items
      transition :smoking
    else
      transition :waiting
    end
  end

  state :smoking do
    @smoking = true
    smoke
  end

  state :done do
    @smoking = false
    puts "#{name} has finished smoking"
    transition :procuring
  end

  def initialize(commodity, rate)
    @commodity, @rate = commodity, rate
    @table = nil

    @cigarette = nil
    @match = nil
    @smoking = false
  end

  def smoking?; @smoking end

  def name
    "#{@commodity} Guy"
  end

  def inspect
    "#<Smoker: #{name}>"
  end

  # Sit down at the table
  def sit(table)
    puts "#{name} sits down at table"
    table.smokers << current_actor # DON'T USE SELF!
    @table = table

    transition :procuring
  end

  # Obtain this smoker's commodity
  def dispense_commodity
    @commodity.new
  end

  # The table should now have the items I need
  def notify_ready
    if state == :smoking
      puts "#{name} says: I'm good on smokes, thanks"
    else
      transition :procuring
    end
  end

  # Take the items from the table
  def take_items
    unless @table.has_complimentary_items? @commodity
      items = @table.items
      if items
        puts "#{name} eyes the table: #{@table.items.map(&:class).join(' and ')} are useless to me!"
      else
        puts "#{name} says: The table is empty!"
      end

      return
    end

    puts "#{name} takes the items from the table"
    items = @table.take

    puts "#{name} whistles for the waitress because the table is empty"
    @table.waitress.whistle!

    tobacco = find_item items, Tobacco
    paper   = find_item items, Paper
    @match  = find_item items, Matches

    @cigarette = paper.roll tobacco
    true
  end

  def find_item(items, type)
    return @commodity.new if type == @commodity
    item = items.find { |i| i.class == type }
    raise "can't find any #{type}" unless item
    item
  end

  def smoke
    @match.light
    @cigarette.light @match

    puts "#{name} enjoys a smoke"
    @cigarette.smoke

    transition :done, :delay => @rate * 5
  end
end

# The waitress fills the table
class Waitress
  include Celluloid

  def initialize(table)
    @table = table
    @refilling = false
  end

  # Handle incoming whistles
  def whistle
    unless @table.smokers.size == 3
      puts "Waitress says: Nothing I can do for ya hon, your party isn't completely seated"
      return
    end

    if @table.items
      puts "Waitress says: The table already has stuff on it!"
    elsif @refilling
      puts "Waitress says: I'm WORKIN' on it! Hold your horses!"
    else
      refill_table
    end
  end

  def refill_table
    @refilling = true

    begin
      smokers = @table.smokers.dup
      receiver = smokers.delete_at rand(smokers.size)
      puts "#{self.class} decides that #{receiver.name} gets to smoke!"

      items = smokers.map { |s| s.dispense_commodity }

      puts "Waitress collects #{items.map(&:class).join(' and ')} and puts them on the table"
      @table.place(items)
    ensure
      @refilling = false
    end

    puts "Waitress tells #{receiver.name} he can smoke now"
    receiver.notify_ready!
    note_smokers
  end

  def note_smokers
    active_smokers = @table.smokers.select { |s| s.smoking? }
    puts "*** Active smokers: #{active_smokers.map(&:name).join(", ")}"
    puts "!!! EVERYBODY SMOKES !!!" if active_smokers.size == @table.smokers.size
  end
end

# The table is the central state holder of the system
class Table
  include Celluloid
  attr_reader :smokers
  attr_reader :waitress
  attr_reader :items

  def initialize
    @smokers = []
    @waitress = Waitress.new(current_actor) # DON'T USE SELF!
    @items = nil
  end

  def place(items)
    raise "there's already stuff on the table" if @items
    @items = items
    puts "Table now contains: #{items.map(&:class).join(', ')}"
    return @items
  end

  def take
    raise "there's nothing on the table" unless @items
    items = @items
    @items = nil
    items
  end

  def has_complimentary_items?(klass)
    return unless @items

    klasses = [Tobacco, Paper, Matches] - [klass]
    @items.map { |i| klasses.include?(i.class) }.all?
  end

  def empty?
    !@items
  end
end

smokers = [
  Smoker.new(Tobacco, 1.0),
  Smoker.new(Paper,   1.5),
  Smoker.new(Matches, 0.3) # he smokes faster because he likes to burn things
]

table = Table.new
smokers.each { |smoker| smoker.sit(table) }

# The main thread is done! Sleep forever
sleep
