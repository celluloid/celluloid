require 'spec_helper'

describe Celluloid::Application do
  before :all do
    class MyActor
      include Celluloid

      def running?; :yep; end
    end

    class MyApplication < Celluloid::Application
      supervise MyActor, :as => :example
    end
  end

  it "runs applications" do
    MyApplication.run!
    sleep 0.01 # startup time hax

    Celluloid::Actor[:example].should be_running
  end
end
