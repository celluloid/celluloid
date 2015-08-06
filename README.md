![Celluloid Supervision](https://raw.github.com/celluloid/celluloid-logos/master/celluloid-supervision/celluloid-supervision.png)

[![Gem Version](https://badge.fury.io/rb/celluloid-supervision.svg)](http://rubygems.org/gems/celluloid-supervision)
[![Build Status](https://secure.travis-ci.org/celluloid/celluloid-supervision.svg?branch=master)](http://travis-ci.org/celluloid/celluloid-supervision)
[![Code Climate](https://codeclimate.com/github/celluloid/celluloid-supervision.svg)](https://codeclimate.com/github/celluloid/celluloid-supervision)
[![Coverage Status](https://coveralls.io/repos/celluloid/celluloid-supervision/badge.svg?branch=master)](https://coveralls.io/r/celluloid/celluloid-supervision)

Supervisors; with Supervision Containers (Groups), Configurations, and Trees for [Celluloid](https://github.com/celluloid/celluloid).


To supervise actors, you have many options:



# Using supervisors.

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


# Using containers.

```ruby
container = Celluloid::Supervision::Container.new {
  supervise type: MyActor, as: :my_actor
  supervise type: MyActor, as: :my_actor_with_args, args: [:one_arg, :two_args]
}
container.run!
```

# Using configuration objects:

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


# Documentation coming:

* Supervision Trees
* Supervised Pools
* Supervised Supervisors



## Contributing

* Fork this repository on github.
* Make your changes and send us a pull request.
* If we like them we'll merge them.
* If we've accepted a patch, feel free to ask for commit access.

## License

Copyright (c) 2011-2015 Tony Arcieri, Donovan Keme.
Distributed under the MIT License. See LICENSE.txt for further details.