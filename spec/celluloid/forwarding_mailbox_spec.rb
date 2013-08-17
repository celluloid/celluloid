require 'spec_helper'

describe Celluloid::ForwardingMailbox do
  let(:mailbox) { Celluloid::Mailbox.new }
  let(:origin) { Celluloid::ForwardingMailbox.new }

  describe '#add_subscriber' do
    it 'adds a subscriber to the list of subscribers' do
      origin.add_subscriber(mailbox)
      origin.subscribers.should include(mailbox)
    end
  end

  describe '#<<' do
    it 'publishes a ForwardingCall to all subscribers' do
      origin.add_subscriber(mailbox)
      mailbox.should_receive(:<<).with(kind_of(Celluloid::ForwardingCall))
      origin << "New work"
    end
  end
end
