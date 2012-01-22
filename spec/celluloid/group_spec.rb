require 'spec_helper'

describe Celluloid::Group do
  before :all do
    class MyActor
      include Celluloid

      def running?; :yep; end
    end

    class MyGroup < Celluloid::Group
      supervise MyActor, :as => :example
    end
  end

  it "runs applications" do
    MyGroup.run!
    sleep 0.01 # startup time hax

    Celluloid::Actor[:example].should be_running
  end
end
