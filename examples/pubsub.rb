require 'celluloid/autostart'

class Publisher 
  include Celluloid
  include Celluloid::Notifications

  def initialize
    now = Time.now.to_f
    sleep now.ceil - now + 0.001
    9.times {
      publish 'example_write_by_instance_method', Time.now
    }
  end
end

class Subscriber
  include Celluloid
  include Celluloid::Notifications
  include Celluloid::Logger

  def initialize
    info "Subscribing to topics."
    subscribe 'example_write_by_instance_method', :new_message
    subscribe 'example_write_by_class_method', :new_message
  end

  def new_message(topic,data)
    info "#{topic}: #{data}"
  end
end

sub = Subscriber.new

Celluloid::Notifications.publish "example_write_by_class_method", Time.now

pub = Publisher.new