source "https://rubygems.org"

gemspec

group :test, :development do
  gem 'faye'
  gem 'goliath'
  gem 'em-synchrony'
  platform :mri do
    gem 'memory_profiler'
  end
end

group :test do
  gem 'guard-rspec'
  gem 'rspec'
end

group :development do
  platform :mri do
    gem 'pry-byebug'
  end
  gem 'rubocop'
  gem 'erubis'
end
