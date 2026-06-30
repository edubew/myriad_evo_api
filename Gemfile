source "https://rubygems.org"

ruby "3.4.7"

gem "rails", "~> 7.1.5", ">= 7.1.5.2"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "tzinfo-data", platforms: %i[ windows jruby ]
gem "bootsnap", require: false

# CORS
gem "rack-cors"

# Authentication
gem 'devise'
gem 'devise-jwt'

# Authorization
gem 'pundit'

# Rate limiting
gem 'rack-attack'

# Pagination
gem 'pagy'

# Serialization
gem 'blueprinter'

# File processing
gem 'image_processing'

# Environment variables
gem 'dotenv-rails'

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]

  # Testing
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'shoulda-matchers'
  gem 'pundit-matchers'
  gem 'faker'
end

group :development do
  # gem "spring"
end
