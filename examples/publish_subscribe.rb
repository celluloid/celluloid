require 'celluloid/zmq'

class PublishSubscribe
  include Celluloid::ZMQ

  def run
    link = "tcp://127.0.0.1:5555"

    s1 = PubSocket.new
    s2 = SubSocket.new
    s3 = SubSocket.new
    s4 = SubSocket.new
    s5 = SubSocket.new

    s1.linger = 100
    s2.subscribe('') # receive all
    s3.subscribe('animals') # receive any starting with this string
    s4.subscribe('animals.dog')
    s5.subscribe('animals.cat')

    s1.bind(link)
    s2.connect(link)
    s3.connect(link)
    s4.connect(link)
    s5.connect(link)

    sleep 1

    topic = "animals.dog"
    payload = "Animal crackers!"

    s1.identity = "publisher-A"
    puts "sending"
    # use the new multi-part messaging support to
    # automatically separate the topic from the body
    s1.write(topic, payload, s1.identity)

    topic = ''
    s2.read(topic)

    body = ''
    s2.read(body) if s2.more_parts?

    identity = ''
    s2.read(identity) if s2.more_parts?
    puts "s2 received topic [#{topic}], body [#{body}], identity [#{identity}]"


    topic = ''
    s3.read(topic)

    body = ''
    s3.read(body) if s3.more_parts?
    puts "s3 received topic [#{topic}], body [#{body}]"

    topic = ''
    s4.read(topic)

    body = ''
    s4.read(body) if s4.more_parts?
    puts "s4 received topic [#{topic}], body [#{body}]"

    s5_string = ''
    s5.read(s5_string)

    # we will never get here
  end
end

PublishSubscribe.new.run
