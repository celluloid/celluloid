require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

RSpec::Core::RakeTask.new(:rcov) do |task|
  task.rcov = true
end

desc "Run Celluloid benchmarks"
task :benchmark do
  load File.expand_path("../benchmarks/objects.rb", __FILE__)
end

task :default => :spec
