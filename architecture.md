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

## Classes
