require 'rails_helper'
require 'mock_redis'

RSpec.describe RateLimiter do
  before do
    $redis = MockRedis.new
  end

  let(:ip) { '1.2.3.4' }
  let(:other_ip) { '5.6.7.8' }

  it 'allows requests below the limit' do
    RateLimiter::LIMIT.times do
      expect(RateLimiter.allowed?(ip)).to be true
    end
  end

  it 'blocks requests above the limit' do
    (RateLimiter::LIMIT + 1).times { RateLimiter.allowed?(ip) }
    expect(RateLimiter.allowed?(ip)).to be false
  end

  it 'sets TTL only on the first hit' do
    expect($redis.ttl("rate_limit:#{ip}")).to eq(-2)  # Key doesn't exist yet

    RateLimiter.allowed?(ip)

    ttl = $redis.ttl("rate_limit:#{ip}")
    expect(ttl).to be_between(1, RateLimiter::WINDOW) # TTL should now exist
    end

  it 'tracks each IP separately' do
    RateLimiter::LIMIT.times do
      expect(RateLimiter.allowed?(ip)).to be true
      expect(RateLimiter.allowed?(other_ip)).to be true
    end

    expect(RateLimiter.allowed?(ip)).to be false
    expect(RateLimiter.allowed?(other_ip)).to be false
  end
end