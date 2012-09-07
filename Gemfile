source 'http://rubygems.org'

gem 'rails', '3.2.6'
gem 'mysql2'
gem 'json'
gem 'haml'
gem 'devise'
gem 'omniauth'
gem 'omniauth-openid'
gem 'oauth2-provider', :require => 'oauth2/provider', :git => 'git@github.com:GSA-OCSIT/oauth2-provider.git', :branch => 'bearer-header'
gem 'rvm-capistrano'
gem 'bigdecimal'
gem 'will_paginate', '~> 3.0'
gem 'rails_admin'
gem 'cancan'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer', :platforms => :ruby
  gem 'execjs'
  gem 'uglifier', '>= 1.0.3'
  gem 'twitter-bootstrap-rails'
end

group :development do
  gem 'haml-rails'
end

group :test, :development do
  gem 'rspec-rails'
  gem 'oauth2'
end

group :test do
  gem 'capybara'
  gem 'launchy'
  gem 'database_cleaner'
  gem 'shoulda-matchers'
end

gem 'jquery-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'

# To use debugger
# gem 'ruby-debug'