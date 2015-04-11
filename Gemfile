source 'https://rubygems.org'
gemspec development_group: :gem_build_tools

gem 'coveralls', require: false

gem 'timers', github: 'celluloid/timers'

# keep these gems in the bundle for now, until the world realizes they are gems ( outside core )
gem 'celluloid-supervision', require: true, github: 'celluloid/celluloid-supervision', branch: "master"
gem 'celluloid-pool', github: 'celluloid/celluloid-pool', branch: "master"
gem 'celluloid-fsm', github: 'celluloid/celluloid-fsm', branch: "master"

group :development do
  gem 'pry'
  gem 'guard'
  gem 'rb-fsevent', '~> 0.9.1' if RUBY_PLATFORM =~ /darwin/
  gem 'guard-rspec'
  gem 'rubocop'
  gem 'rspec', '~> 3.2'
  gem 'rspec-log_split', github: 'abstractive/rspec-log_split', branch: 'master'
end

group :test do
  gem 'dotenv', '~> 2.0'
  gem 'nenv'
  gem 'benchmark_suite'
  gem 'rspec', '~> 3.2'
  gem 'rspec-retry'
end

group :gem_build_tools do
  gem 'rake'
end
