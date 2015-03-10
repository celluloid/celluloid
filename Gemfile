source 'https://rubygems.org'
gemspec development_group: :gem_build_tools

gem 'coveralls', require: false
gem 'pry'

gem 'timers', github: 'celluloid/timers'

if RUBY_PLATFORM =~ /darwin/
  gem 'rb-fsevent', '~> 0.9.1'
end

group :development do
  gem 'rspec', '~> 3.2'
  gem 'guard-rspec'
  gem 'benchmark_suite'
  gem 'rubocop'
  gem 'transpec'
end

group :gem_build_tools do
  gem 'rake'
end
