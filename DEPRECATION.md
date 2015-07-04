# Celluloid is deprecating code.

As of `0.17.0` changes are being made which alter the behavior, naming, and syntax of various objects. Many of those are foundational components.

We put up a warning to encourage refactoring that looks like this, if `Celluloid` is being required by `require 'celluloid'` or `require 'celluloid/autostart'`:

```
WARN -- : +--------------------------------------------------+
WARN -- : |     Celluloid is running in BACKPORTED mode.     |
WARN -- : |   Time to update deprecated code, before v1.0!   |
WARN -- : +--------------------------------------------------+
WARN -- : |  Prepare! As of v0.17.5 you can begin updating.  |
WARN -- : +--------------------------------------------------+
WARN -- : |    Want to read about it? http://git.io/vJf3J    |
WARN -- : +--------------------------------------------------+
```

Or, if `Celluloid` is being run in in backported mode intentionally, using `require 'celluloid/backported'` it looks like this:

```
WARN -- : Celluloid is running in BACKPORTED mode. [ http://git.io/vfteb ]
```

## It is might be very important that you make changes to your code.

Try requiring `Celluloid` using this method:

```
require 'celluloid/current'
```

That will turn *off* BACKPORTED mode, and only give you the up-to-date system.

Please read about this, here: http://git.io/vJf3J