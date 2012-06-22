require 'spec_helper'

describe Celluloid::Notifications do
  class Admirer
    include Celluloid
    include Celluloid::Notifications

    attr_reader :mourning

    def someone_died(topic, name)
      @mourning = name
    end
  end

  class President
    include Celluloid
    include Celluloid::Notifications

    def die
      publish("death", "Mr. President")
    end
  end

  it 'notifies subscribers' do
    marilyn = Admirer.new
    jackie = Admirer.new

    marilyn.subscribe("death", :someone_died)
    jackie.subscribe("death", :someone_died)

    president = President.new

    president.die
    marilyn.mourning.should == "Mr. President"
    jackie.mourning.should == "Mr. President"
  end

  it 'publishes even if there are no subscribers' do
    president = President.new
    president.die
  end

  it 'allows regex subscriptions' do
    marilyn = Admirer.new

    marilyn.subscribe(/(death|assassination)/, :someone_died)

    president = President.new
    president.die
    marilyn.mourning.should == "Mr. President"
  end

  it 'allows unsubscribing' do
    marilyn = Admirer.new

    subscription = marilyn.subscribe("death", :someone_died)
    marilyn.unsubscribe(subscription)

    president = President.new
    president.die
    marilyn.mourning.should be_nil
  end

  it 'prunes dead subscriptions' do
    marilyn = Admirer.new
    jackie = Admirer.new

    marilyn.subscribe("death", :someone_died)
    jackie.subscribe("death", :someone_died)

    listeners = Celluloid::Notifications.notifier.listeners_for("death").size
    marilyn.terminate
    after_listeners = Celluloid::Notifications.notifier.listeners_for("death").size

    after_listeners.should == listeners - 1
  end
end
