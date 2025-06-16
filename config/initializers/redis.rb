require "redis"

$redis = Redis.new(url: ENV["REDIS_URL"] || "redis://redis:6379/0")

# Set Redis as the cache store
Rails.application.config.cache_store = :redis_cache_store, { 
  url: ENV["REDIS_URL"] || "redis://redis:6379/0",
  expires_in: 1.hour
}
