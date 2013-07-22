require 'spec_helper'

describe Celluloid::IO::DNSResolver do
  describe '#resolve' do
    it 'resolves hostnames' do
      resolver = Celluloid::IO::DNSResolver.new
      resolver.resolve('localhost').should eq Resolv::IPv4.create("127.0.0.1")
    end

    it "resolves domain names" do
      resolver = Celluloid::IO::DNSResolver.new
      resolver.resolve("celluloid.io").should == Resolv::IPv4.create("207.97.227.245")
    end

    it "resolves CNAME responses" do
      resolver = Celluloid::IO::DNSResolver.new
      results = resolver.resolve("www.google.com")
      if results.is_a?(Array)
        results.all? {|i| i.should be_an_instance_of(Resolv::IPv4) }
      else
        results.should be_an_instance_of(Resolv::IPv4)
      end
      # www.yahoo.com will be resolved randomly whether multiple or
      # single entry.
      results = resolver.resolve("www.yahoo.com")
      if results.is_a?(Array)
        results.all? {|i| i.should be_an_instance_of(Resolv::IPv4) }
      else
        results.should be_an_instance_of(Resolv::IPv4)
      end
    end
  end
end
