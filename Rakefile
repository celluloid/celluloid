require "bundler/gem_tasks"

Dir["tasks/**/*.rake"].each { |task| load task }

default_tasks = ["spec"]
default_tasks << "rubocop" unless ENV["CI"]
task default: default_tasks

task ci: %w(spec benchmark)
