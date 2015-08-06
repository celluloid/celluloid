Supervisors, Supervision Groups, and Supervision Trees for Celluloid.

# Using supervisors.

To supervise an actor, you have several options:

### Directly

```ruby
MyActor.supervise as: :my_actor # Without arguments.
MyActor.supervise as: :my_actor, args: [:one_arg, :two_args]
```

### Indirectly

```ruby
Celluloid.supervise as: :my_actor, type: MyActor # Without arguments.
Celluloid.supervise as: :my_actor, type: MyActor, args: [:one_arg, :two_args]
```

### By pre-made configuration object:

```ruby
config = Celluloid::Supervision::Configuration.define([
  {
    type: MyActor,
    as: :my_actor
  },
  {
    type: MyActor,
    as: :my_actor_with_args,
    args: [
      :one_arg,
      :two_args
    ]
  },
])

# Whenever you would like to deploy the actors:
config.deploy

# Whenver you would like to shut them down:
config.shutdown

# Reuse the same configuration if you like!
config.deploy
```

### By on-going configuration object:

```ruby
config = Celluloid::Supervision::Configuration.new
config.define type: MyActor, as: :my_actor
config.define type: MyActor, as: :my_actor_with_args, args: [:one_arg, :two_args]
config deploy

# Now add actors to the already running configuration.
config.add type: MyActor, as: :my_actor_deployed_immediately
config.shutdown
```
