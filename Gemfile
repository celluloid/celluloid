source 'https://rubygems.org'
gemspec

gem 'coveralls', require: false
gem 'pry'

platforms :rbx do
  gem 'rubysl', '~> 2.0'
  gem 'json'
  gem 'rubinius-developer_tools'
end


if RUBY_PLATFORM =~ /darwin/
  gem 'rb-fsevent', '~> 0.9.1'
end
