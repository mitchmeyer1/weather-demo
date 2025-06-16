#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails
rm -f /app/tmp/pids/server.pid

# Create necessary directories
mkdir -p /app/tmp/pids
mkdir -p /app/log

# Check if we need to create the Rails application
if [ ! -f /app/config/application.rb ]; then
  echo "Creating new Rails application..."
  rails new . --skip-active-record --skip-action-mailbox --skip-action-text --skip-active-storage --force
  
  # Add Redis gem
  bundle add redis
  bundle add redis-rails
  
  # Create directories for controllers and views
  mkdir -p app/controllers/api/v1
  mkdir -p app/views/home
  
  # Create Redis initializer
  mkdir -p config/initializers
  echo 'require "redis"

$redis = Redis.new(url: ENV["REDIS_URL"] || "redis://redis:6379/0")

# Set Redis as the cache store
Rails.application.config.cache_store = :redis_cache_store, { 
  url: ENV["REDIS_URL"] || "redis://redis:6379/0",
  expires_in: 1.hour
}' > config/initializers/redis.rb

  echo "Rails application created successfully!"
fi

# Execute the main container command
exec "$@"

