require 'spec_helper'

describe Celluloid::IO::DNSResolver do
  it "resolves domain names" do
    resolver = Celluloid::IO::DNSResolver.new
    resolver.resolve("celluloid.io").should == Resolv::IPv4.create("207.97.227.245")
  end
end