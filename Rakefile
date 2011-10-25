require 'rubygems'
require 'bundler'
require 'timeout'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

RSpec::Core::RakeTask.new(:rcov) do |task|
  task.rcov = true
end

desc "Run Celluloid benchmarks"
task :benchmark do
  begin
    Timeout.timeout(120) do
      load File.expand_path("../benchmarks/objects.rb", __FILE__)
    end
  rescue => ex
    puts "ERROR: Couldn't complete benchmark: #{ex.class}: #{ex}"
  end
end

task :default => %w(spec benchmark)
