source 'https://rubygems.org'

gem 'coveralls', require: false

gem 'timers', github: 'celluloid/timers'

# keep these gems in the bundle for now, until the world realizes they are gems ( outside core )
gem 'celluloid-supervision', github: 'celluloid/celluloid-supervision', branch: "master"
gem 'celluloid-pool', github: 'celluloid/celluloid-pool', branch: "master"
gem 'celluloid-fsm', github: 'celluloid/celluloid-fsm', branch: "master"
gem 'celluloid-extras', github: 'celluloid/celluloid-extras', branch: "master"

gemspec development_group: :gem_build_tools

group :development do
  gem 'pry'
  gem 'guard'
  gem 'rb-fsevent', '~> 0.9.1' if RUBY_PLATFORM =~ /darwin/
  gem 'guard-rspec'
  gem 'rubocop', '~> 0.30.0'
  gem 'rspec-log_split', github: 'abstractive/rspec-log_split', branch: 'master'
end

group :test do
  gem 'dotenv', '~> 2.0'
  gem 'nenv'
  gem 'benchmark_suite'
  gem 'rspec', '~> 3.2'
end

group :gem_build_tools do
  gem 'rake'
end
