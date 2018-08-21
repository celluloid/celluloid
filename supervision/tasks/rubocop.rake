unless ENV["CI"]
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
end
