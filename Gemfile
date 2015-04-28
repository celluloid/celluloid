source "https://rubygems.org"

gem "bundler"
gem "coveralls", require: false
gemspec

group :development do
  gem "pry"
  gem "guard"
  gem "rb-fsevent", "~> 0.9.1" if RUBY_PLATFORM =~ /darwin/
  gem "guard-rspec"
  gem "rubocop"
end

group :test do
  gem "dotenv", "~> 2.0"
  gem "nenv"
  gem "benchmark_suite"
  gem "rspec", "~> 3.2"
  gem "rspec-retry"
  gem "rspec-log_split", github: "abstractive/rspec-log_split", branch: "master"
end

group :gem_build_tools do
  gem "rake"
end

gem "celluloid-essentials", github: "celluloid/celluloid-essentials", branch: "master"
gem 'celluloid-extras', github: 'celluloid/celluloid-extras', branch: 'master'
gem 'celluloid-supervision', github: 'celluloid/celluloid-supervision', branch: 'master'
gem 'celluloid-pool', github: 'celluloid/celluloid-pool', branch: 'master'
gem 'celluloid-fsm', github: 'celluloid/celluloid-fsm', branch: 'master'
gem "timers", github: "celluloid/timers"
