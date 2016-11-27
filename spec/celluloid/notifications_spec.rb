RSpec.describe Celluloid::Notifications, actor_system: :global do
  class Admirer
    include Celluloid
    include Celluloid::Notifications

    attr_reader :mourning
    attr_reader :mourning_count

    def someone_died(_topic, name)
      @mourning = name
      @mourning_count ||= 0
      @mourning_count += 1
    end
  end

  class President
    include Celluloid
    include Celluloid::Notifications

    def die(topic = "death")
      publish(topic, "Mr. President")
    end
  end

  it "notifies relevant subscribers" do
    marilyn = Admirer.new
    jackie = Admirer.new

    marilyn.subscribe("death", :someone_died)
    jackie.subscribe("alive", :someone_died)

    president = President.new

    president.die
    expect(marilyn.mourning).to eq("Mr. President")
    expect(jackie.mourning).not_to eq("Mr. President")
  end

  it "allows multiple subscriptions from the same actor" do
    marilyn = Admirer.new

    marilyn.subscribe("death", :someone_died)
    marilyn.subscribe("death", :someone_died)

    president = President.new

    president.die
    expect(marilyn.mourning_count).to be(2)
  end

  it "notifies subscribers" do
    marilyn = Admirer.new
    jackie = Admirer.new

    marilyn.subscribe("death", :someone_died)
    jackie.subscribe("death", :someone_died)

    president = President.new

    president.die
    expect(marilyn.mourning).to eq("Mr. President")
    expect(jackie.mourning).to eq("Mr. President")
  end

  it "publishes even if there are no subscribers" do
    president = President.new
    president.die
  end

  it "allows symbol subscriptions" do
    marilyn = Admirer.new
    jackie = Admirer.new

    marilyn.subscribe(:death, :someone_died)
    jackie.subscribe("death", :someone_died)

    president = President.new
    president.die(:death)
    expect(marilyn.mourning).to eq("Mr. President")
    expect(jackie.mourning).to eq("Mr. President")
  end

  it "allows regex subscriptions" do
    marilyn = Admirer.new

    marilyn.subscribe(/(death|assassination)/, :someone_died)

    president = President.new
    president.die
    expect(marilyn.mourning).to eq("Mr. President")
  end

  it "matches symbols against regex subscriptions" do
    marilyn = Admirer.new

    marilyn.subscribe(/(death|assassination)/, :someone_died)

    president = President.new
    president.die(:assassination)
    expect(marilyn.mourning).to eq("Mr. President")
  end

  it "allows unsubscribing" do
    marilyn = Admirer.new

    subscription = marilyn.subscribe("death", :someone_died)
    marilyn.unsubscribe(subscription)

    president = President.new
    president.die
    expect(marilyn.mourning).to be_nil
  end

  it "prunes dead subscriptions" do
    marilyn = Admirer.new
    jackie = Admirer.new

    marilyn.subscribe("death", :someone_died)
    jackie.subscribe("death", :someone_died)

    listeners = Celluloid::Notifications.notifier.listeners_for("death").size
    marilyn.terminate
    after_listeners = Celluloid::Notifications.notifier.listeners_for("death").size

    expect(after_listeners).to eq(listeners - 1)
  end

  it "prunes multiple subscriptions from a dead actor" do
    marilyn = Admirer.new

    marilyn.subscribe("death", :someone_died)
    marilyn.subscribe("death", :someone_died)

    listeners = Celluloid::Notifications.notifier.listeners_for("death").size
    marilyn.terminate
    after_listeners = Celluloid::Notifications.notifier.listeners_for("death").size

    expect(after_listeners).to eq(listeners - 2)
  end
end
