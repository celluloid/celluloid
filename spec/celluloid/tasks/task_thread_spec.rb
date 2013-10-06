require 'spec_helper'

describe Celluloid::TaskThread do
  around(:each) do |example|
    Celluloid::ActorSystem.new.within { example.run }
  end

  it_behaves_like "a Celluloid Task", Celluloid::TaskThread
end
