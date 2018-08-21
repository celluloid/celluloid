source "https://rubygems.org"

gemspec

group :development do
  gem "pry"
end

group :test do
  gem "benchmark-ips",           require: false
  gem "coveralls",   ">= 0.8",   require: false
  gem "rspec",       "~> 3",     require: false
  gem "rspec-retry", "~> 0.5",   require: false
  gem "rubocop", "= 0.58.2", require: false
end

group :development, :test do
  gem "rake"
end
