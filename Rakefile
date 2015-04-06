require "bundler/gem_tasks"
Dir["tasks/**/*.task"].each { |task| load task }

task :default => :spec
task :ci      => %w(spec benchmark)
