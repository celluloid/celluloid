shared_context "an Always Exclusive Celluloid Actor" do |included_module|

  let(:actor_class) { AlwaysExclusiveActorClass.create(included_module) }

  it "executes two methods in an exclusive order" do
    actor = actor_class.new
    actor.eat_donuts!
    actor.drink_coffee!
    sleep 4
    actor.tasks.should == ['donuts', 'coffee']
  end
end
