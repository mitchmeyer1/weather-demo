module RateLimiter
  LIMIT = 100
  WINDOW = 60 # seconds

  def self.allowed?(ip)
    key = "rate_limit:#{ip}"
    count = $redis.incr(key)
    $redis.expire(key, WINDOW) if count == 1
    count <= LIMIT
  end
end