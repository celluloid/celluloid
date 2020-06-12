# ![Celluloid][celluloid-logo-image-raw]

[![Gem Version][gem-image]][gem-link]
[![MIT licensed][license-image]][license-link]
[![Build Status][build-image]][build-link]
[![Maintained: no][maintained-image]][maintained-link]
[![Gitter Chat][gitter-image]][gitter-link]

[celluloid-logo-image-raw]: https://raw.github.com/celluloid/celluloid-logos/master/celluloid/celluloid.png
[gem-image]: https://badge.fury.io/rb/celluloid.svg
[gem-link]: http://rubygems.org/gems/celluloid
[build-image]: https://secure.travis-ci.org/celluloid/celluloid.svg?branch=master
[build-link]: http://travis-ci.org/celluloid/celluloid
[license-image]: https://img.shields.io/badge/license-MIT-blue.svg
[license-link]: https://github.com/celluloid/celluloid/blob/master/LICENSE.txt
[maintained-image]: https://img.shields.io/maintenance/no/2016.svg
[maintained-link]: https://github.com/celluloid/celluloid/issues/779
[gitter-image]: https://badges.gitter.im/badge.svg
[gitter-link]: https://gitter.im/celluloid/celluloid

Celluloid is a framework for building asynchronous and multithreaded Ruby
programs using object-oriented concepts.

## Revival Process Underway

`Celluloid` is in the process of being refactored and released back into the wild during `Google Summer of Code`. The next era will not have one individual active maintainer, but a team of collaborators. Going forward, previously dormant maintainer [Donovan Keme](https://github.com/digitalextremist) is returning to support future primary maintainer [Emese Padányi](https://github.com/emesepadanyi) during `GSoC 2020`. Her plan extends past the Summer program, and aims to revive the community and codebase of `Celluloid` together. Backing this process are [Harsh Deep](https://github.com/harsh183) and `GSoC` alumni [Dilum Navanjana](https://github.com/dilumn). We welcome your collaboration and contributions in this massive work.

The codebase is being refactored to pursue a stable release with no deprecation warnings, and with this cleaned up:

# ![Diagram][celluloid-diagram]
*Diagram meticulously developed by [Emese Padányi](https://github.com/emesepadanyi)*

[celluloid-diagram]: https://raw.githubusercontent.com/celluloid/celluloid/master/documentation/ClassDiagram-class_diagram.png

### Proudly supported by the best cloud infrastructure provider in the world: [`DigitalOcean`](https://digitalocean.com)

## Discussion

- [Gitter Chat][gitter-link]
- [Google Group](https://groups.google.com/group/celluloid-ruby)

## Documentation

[Please see the Celluloid Wiki](https://github.com/celluloid/celluloid/wiki)
for more detailed documentation and usage notes.

The following API documentation is also available:

* [YARD API documentation](http://rubydoc.info/gems/celluloid/frames)
* [Celluloid module (primary API)](http://rubydoc.info/gems/celluloid/Celluloid)
* [Celluloid class methods](http://rubydoc.info/gems/celluloid/Celluloid/ClassMethods)
* [All Celluloid classes](http://rubydoc.info/gems/celluloid/index)

## Related Projects

See also: [Projects Using Celluloid](https://github.com/celluloid/celluloid/wiki/Projects-Using-Celluloid)

* [Reel][reel]: An "evented" web server based on `Celluloid::IO`
* [DCell][dcell]: The Celluloid actor protocol distributed over 0MQ
* [ECell][ecell]: Mesh strategies for `Celluloid` actors distributed over 0MQ
* [Celluloid::IO][celluloid-io]: "Evented" IO support for `Celluloid` actors
* [Celluloid::ZMQ][celluloid-zmq]: "Evented" 0MQ support for `Celluloid` actors
* [Celluloid::DNS][celluloid-dns]: An "evented" DNS server based on `Celluloid::IO`
* [Celluloid::SMTP][celluloid-smtp]: An "evented" SMTP server based on `Celluloid::IO`
* [nio4r][nio4r]: "New IO for Ruby": high performance IO selectors
* [Timers][timers]: A generic Ruby timer library for event-based systems

[reel]: https://github.com/celluloid/reel/
[dcell]: https://github.com/celluloid/dcell/
[ecell]: https://github.com/abstractive/ecell/
[celluloid-io]: https://github.com/celluloid/celluloid-io/
[celluloid-zmq]: https://github.com/celluloid/celluloid-zmq/
[celluloid-dns]: https://github.com/celluloid/celluloid-dns/
[celluloid-smtp]: https://github.com/abstractive/celluloid-smtp/
[nio4r]: https://github.com/celluloid/nio4r/
[timers]: https://github.com/celluloid/timers/

## Contributing to Celluloid

- Fork this repository on github
- Make your changes and send us a pull request
- Pull requests will be reviewed for inclusion in the project

## License

Copyright (c) 2011-2018 Tony Arcieri, Donovan Keme.

Distributed under the MIT License. See [LICENSE.txt](https://github.com/celluloid/celluloid/blob/master/LICENSE.txt)
for further details.
