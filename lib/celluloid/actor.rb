module Celluloid
  # Actors are Celluloid's concurrency primitive. They're implemented as
  # normal Ruby objects wrapped in threads which communicate with asynchronous
  # messages. The implementation is inspired by Erlang's gen_server
  module Actor
    attr_reader :celluloid_mailbox
    
    module ClassMethods  
      def spawn(*args, &block)
        actor = allocate
        actor.__initialize_actor(*args, &block)
        
        ActorProxy.new(actor) 
      end
    end
    
    # Actor-specific initialization
    def __initialize_actor(*args, &block)
      @celluloid_mailbox = Mailbox.new
      
      # Call the object's normal initialize method
      initialize(*args, &block)
      
      Thread.new do
        Thread.current[:celluloid_mailbox] = @celluloid_mailbox
        __process_messages
      end
    end
    
    # Process incoming messages
    def __process_messages
      while true # instead of loop, for speed!
        message = @celluloid_mailbox.receive
        type = message[0]
        
        case type
        when :call
          _, caller, meth, args, block = message
          
          begin
            result = send meth, *args, &block
            caller << [:reply, :value, result]
          rescue NoMethodError => ex
            caller << [:reply, :error, ex]
          end
        when :cast
          _, _, meth, args, block = message
          send meth, *args, &block
        else
          raise "don't know how to handle #{type.inspect} messages!"
        end
      end
    rescue Exception => ex
      __handle_crash(ex)
    end
    
    # Handle any exceptions that occur within a running actor
    def __handle_crash(ex)
      puts "*** #{self.class} CRASH: #{ex.class}: #{ex.to_s}\n#{ex.backtrace.join("\n")}"
    end
  
    def self.included(klass)
      klass.extend(ClassMethods)
    end
  end
end