# Architecture

The purpose of this document is to provide an overview of the `Celluloid` project architecture. It is intended as a learning tool for
GSoC (Google Summer of Code) and for anyone else interested in peeking under the hood to figure out how Celluloid works.

This document will evolve since the people writing it are learning the project too. It will likely evolve in the following manner:

1. Document all major classes by describing the purpose of each one.
2. Document the dependencies between classes described in item 1.
3. Describe the flow of messages between the classes documented in items 1 and 2.
4. Generate a Big Picture overview of the overall Celluloid architecture.
5. Create a flew graphics to depict class dependencies and message flows (perhaps as a directed acyclic graph).

## Document Status

The document is working on item 1.

## Required Libraries
`logger`
`thread`
`timeout`
`set`

## Require Lifecycle
Document the steps taken from the moment `require "celluloid"` is executed by the runtime.

The file `celluloid.rb` is read in by the runtime. This file requires some standard libraries like `Thread` and `Set` (see Required Libraries for full list) and initializes the `Celluloid` module namespace. It then sets up a Celluloid singleton class which will contain utility functions that need to be accessed from anywhere. Think of these singleton methods as global methods. These specific methods should be considered private to the library and should not be directly called by user code.

From here it continues to `extend` and `include` other modules so that any Ruby object that executes `include Celluloid` as part of its class definition automatically gains all of the Celluloid magic. 

Next, it defines regular methods within the Celluloid namespace. These are also global methods but they are essentially the public API to the outside world. These methods (such as `current_actor` and `terminate`) can be called by user code.

Next we have a list of `require`'d subfiles. This loads the remainder of the library in preparation to start running.

Next, the code sets up two global default settings for the `task_class` and `group_class`. I don't know what these are yet but by exposing them this way it's clearly intended for these items to be defined in such a way that user code can override them with use-case-specific code. The code here can also read names from the environment variables to set the defaults. This is likely intended for use by the spec/test system.

Lastly, the code registers some methods for shutdown to terminate all actors `at_exit` and then initializes the system.

To boot the system, code is clearly intended to `require 'celluloid/current'` or `require 'celluloid/backported'` which in turn call `require 'celluloid/autostart'`. Autostart finishes the initialization sequence by calling the equivalent to `Actor::System.new.start`.
## Classes / Modules

### Celluloid Module
* Sets up class accessors used throughout/globally such as `logger`
* When using `include Celluloid` on a class, it performs the following work during `include`:
  * Extends `ClassMethods` and `Internals::Properties`
  * Includes `InstanceMethods`
  * Sets properties on the class object.
  * Removes `trap_exit` and `exclusive` if they exist on the singleton class so that Celluloid can redefine them for itself.
* Defines class methods inside the `Celluloid` namespace such as `actor?` and `mailbox` and `cores`. These are utility functions. They are defined on the Celluloid singleton.
* Provides the entry method `boot` to start up the whole system and its opposite `shutdown` to terminate everything.

#### Depends On Classes
* Internals::Logger
* Internals::CallChain
* Actor::System
* Celluloid::Mailbox
* Thread (primarily for Thread.current to access fiber locals like `:celluloid_actor`)
* Future

### ClassMethods Module
This class contains class-level methods which are added to every user class that contains `include Celluloid`. 

* Overrides `new` for the class object.

#### Depends On Classes
* Cell
* Actor
* Celluloid

### InstanceMethods Module
This module contains instance-level methods which are added to every user class that contains `include Celluloid`.

#### Depends on Classes
* Actor
* Celluloid
