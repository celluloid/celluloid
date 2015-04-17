source 'https://rubygems.org'
gemspec development_group: :gem_build_tools

gem 'coveralls', require: false

group :development do
  gem 'pry'
  gem 'guard'
  gem 'rb-fsevent', '~> 0.9.1' if RUBY_PLATFORM =~ /darwin/
  gem 'rubocop'
end

group :test do
  gem 'dotenv', '~> 2.0'
  gem 'nenv'
  gem 'guard-rspec'
  gem 'benchmark_suite'
  gem 'rspec', '~> 3.2'
  gem 'rspec-retry'
  gem 'rspec-log_split', github: 'abstractive/rspec-log_split', branch: 'master'
  gem 'celluloid', github: 'celluloid/celluloid', branch: '0.17.0-prerelease'
end

group :gem_build_tools do
  gem 'rake'
end
