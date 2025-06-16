require 'rails_helper'
require 'webmock/rspec'

RSpec.describe WeatherApi do
  describe '.fetch' do
    let(:lat) { 40.6561 }
    let(:lon) { -73.94958 }
    let(:timezone) { 'America/New_York' }
    let(:url) do
      "https://api.open-meteo.com/v1/forecast?timezone=#{timezone}&latitude=#{lat}&longitude=#{lon}&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,rain_sum,snowfall_sum,showers_sum,precipitation_probability_max&hourly=temperature_2m,precipitation_probability,rain,showers,snowfall&current=rain,showers,snowfall,precipitation,temperature_2m,is_day,wind_speed_10m,wind_direction_10m"
    end

    let(:api_response) do
      {
        "latitude" => lat,
        "longitude" => lon,
        "timezone" => timezone,
        "current" => { "temperature_2m" => 22.5 }
      }.to_json
    end

    it 'returns parsed weather data for valid input' do
      stub_request(:get, url).to_return(status: 200, body: api_response, headers: { 'Content-Type' => 'application/json' })

      result = described_class.fetch(lat, lon, timezone)
      expect(result['current']['temperature_2m']).to eq(22.5)
    end

    it 'raises error for invalid latitude' do
      expect {
        described_class.fetch(123.456, lon, timezone)
      }.to raise_error("Invalid latitude: 123.456")
    end

    it 'raises error for invalid longitude' do
      expect {
        described_class.fetch(lat, -999.99, timezone)
      }.to raise_error("Invalid longitude: -999.99")
    end

    it 'raises error for invalid timezone format' do
      expect {
        described_class.fetch(lat, lon, 'AmericaNewYork')
      }.to raise_error("Invalid timezone format: AmericaNewYork")
    end
  end
end