# Contribution Guidelines

If you are seeking support, or for discussions about Celluloid, you can use [the mailing list](http://groups.google.com/group/celluloid-ruby) or the IRC channel, #celluloid on freenode.

If you encounter an issue with Celluloid itself, you should go through the following checklist:

* Is this a known bug or are you falling into a common trap? Check the [Gotchas wiki page](https://github.com/celluloid/celluloid/wiki/Gotchas).
* Is there already an issue filed which looks like your issue? Check the [issue tracker](https://github.com/celluloid/celluloid/issues).
* Is the problem present in the latest released version of Celluloid? Upgrade and check!
* Is the problem present on the master branch of Celluloid? [Run pre-release](#running-pre-release-celluloid) from source control and check!

If you don't get anywhere with this checklist, please feel free to [file a bug report](#filing-a-bug-report).

## Running pre-release Celluloid

If you encounter a bug, it's entirely possible that it has already been fixed but not yet included in a released version. You can establish this by trying to run your application with a pre-release version of Celluloid direct from source control. You can do this by modifying your application's Gemfile as follows:

```ruby
gem 'celluloid', github: 'celluloid', submodules: true
```

If it is suggested to you that you try a different branch, add `branch: 'somebranch'`.

If the problem is resolved, feel free to voice your desire for a new release of Celluloid on IRC (`irc.freenode.net/#celluloid`). 

If it persists, you should consider [filing a bug report](#filing-a-bug-report).

## Filing a bug report

* Bug reports should be filed on the [GitHub issue tracker](https://github.com/celluloid/celluloid/issues). Bug reports should contain the following things:
  * A sensible subject that helps quickly identify the issue.
  * Full steps to reproduce the issue, including minimal reproduction code. A minimal reproduction means only what is necessary to display the problem and nothing more. This is perhaps the most important thing, don't skip it!
  * Output from a reproduction.
  * Full references for version numbers (of Celluloid, dependencies, Ruby, Operating System, etc). One easy way to do this is to post your Gemfile.lock, though you will still need to tell us what version of Ruby is in use.
* See: [Triage Process](https://github.com/celluloid/celluloid/wiki/Triage-Process)
* Some more guidelines on filing good bug reports:
  * http://www.chiark.greenend.org.uk/~sgtatham/bugs.html
  * http://itscommonsensestupid.blogspot.com/2008/07/tips-to-write-good-bug-report.html
  * http://timheuer.com/blog/archive/2011/10/12/anatomy-of-a-good-bug-report.aspx
