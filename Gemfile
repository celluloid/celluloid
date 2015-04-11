source 'https://rubygems.org'
gemspec development_group: :gem_build_tools

gem 'coveralls', require: false

gem 'celluloid', github: 'abstractive/celluloid', branch: 'master'

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
  gem 'rspec-log_split', github: 'abstractive/rspec-log_split', branch: 'master'
end

group :gem_build_tools do
  gem 'rake'
end
