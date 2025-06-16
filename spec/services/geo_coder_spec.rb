require 'rails_helper'
require 'webmock/rspec'

RSpec.describe GeoCoder do
  describe '.lookup' do
    let(:zip) { '11211' }
    let(:url) { "https://geocoding-api.open-meteo.com/v1/search?name=#{zip}&country=US" }

    let(:api_response) do
      {
        results: [
          {
            latitude: 40.6561,
            longitude: -73.94958,
            timezone: 'America/New_York'
          }
        ]
      }.to_json
    end

    it 'returns coordinates and timezone from API' do
      stub_request(:get, url).to_return(status: 200, body: api_response, headers: { 'Content-Type' => 'application/json' })

      result = described_class.lookup(zip)

      expect(result).to eq(
        lat: 40.6561,
        lon: -73.94958,
        timezone_code: 'America/New_York'
      )
    end

    it 'returns nil when no results are present' do
      stub_request(:get, url).to_return(status: 200, body: { results: [] }.to_json)

      expect(described_class.lookup(zip)).to be_nil
    end

    it 'raises an error for an invalid zip code format' do
      invalid_zip = 'ABC12'

      expect {
        described_class.lookup(invalid_zip)
      }.to raise_error("Invalid zip format: #{invalid_zip}")
    end
    
  end
end