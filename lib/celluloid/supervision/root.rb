# supervision in Celluloid is really an aspect of ActorSystem
# out-sourced to other sub-systems, like Group::* and more
# this needs to be defined in the ActorSystem namespace

# TODO: Decide which class method routes to support!
#       Supporting Celluloid.*, Celluloid::ActorSystem.*,
#       and Celluloid::Supervisor.* all at once is a bad idea.
module Celluloid

  extend Forwardable
  def_delegators :"actor_system.registry", :[], :[]=, :root
  
  class Supervisor
    class << self
      
      # Define the root of the supervision tree
      # Holding essential "system services"
      # And hosting the services group
      def root
        Celluloid.actor_system.root
      end
    end
  end

  class ActorSystem

    extend Forwardable
    def_delegators :@registry, :[], :get, :[]=, :set, :delete
    
    # root of supervision tree
    @tree = nil

    def root
      @tree
    end

    # definition of supervision tree
    @@root = Supervision::Services::Root.define([
      {
        :as => :notifications_fanout,
        :type => Celluloid::Notifications::Fanout
      },
      {
        :as => :default_incident_reporter,
        :type => Celluloid::IncidentReporter,
        :args => [ STDERR ]
      }
    ])

    def deploy(add=[])
      @@root.define(
        [
          {
            :as => :group_manager,
            :type => Celluloid::Group::Manager,
            :args => [ @group ],
            :accessors => [ :manager, :group_manager ]
          },
          {
            :as => :public_services,
            :type => Celluloid::Supervision::Services::Public,
            :accessors => [ :services, :public_services ]
          }
        ] + add
      )
      puts "\n@@root? ------------------\n #{@@root.instances.map { |i| "INSTANCE: #{i.as} ... #{i.args}" }}\n"
      @@root.deploy
    end

    extend Forwardable
    def_delegators :@registry, :[], :get, :[]=, :set, :delete

    class << self

      def root
        @tree
      end

      def add(instance)
        if instance.is_a? Array or instance.is_a? Supervision::Configuration
          instance.each { |s| add(s) } # individually validate configurations
          return
        else
          service = Supervision::Configuration.options(instance)
          @@root << service unless @@root.select { |s| s[:as] == service [:as] }.any?
          return
        end
        raise Supervision::Configuration::Error::Invalid
      end
      alias :<< :add
    end
  end
end
