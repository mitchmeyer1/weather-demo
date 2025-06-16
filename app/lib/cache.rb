
class Cache
  def self.read(key)
    val = $redis.get(key)
    val.present? ? JSON.parse(val) : nil
  end

  def self.write(key, value, ttl)
    $redis.set(key, value.to_json, ex: ttl)
  end
end