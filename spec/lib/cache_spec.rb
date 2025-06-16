require 'rails_helper'
require 'mock_redis'

RSpec.describe Cache do
  before do
    $redis = MockRedis.new
  end

  it 'writes and reads JSON-encoded values' do
    key = 'test_key'
    value = { foo: 'bar' }

    Cache.write(key, value, 60)
    result = Cache.read(key)

    expect(result).to eq(value.stringify_keys)
  end

  it 'returns nil for missing keys' do
    expect(Cache.read('missing')).to be_nil
  end

  it 'respects TTL expiration' do
    key = 'temp_key'
    Cache.write(key, { foo: 'bar' }, 1)
    sleep 2
    expect(Cache.read(key)).to be_nil
  end
end