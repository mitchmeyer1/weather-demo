require 'rails_helper'

RSpec.describe WeatherFetcher do
  describe '.call' do
    let(:zip) { '11211' }
    let(:geo_data) do
      { lat: 40.6561, lon: -73.94958, timezone_code: 'America/New_York' }
    end
    let(:raw_weather) do
      {
        'timezone' => 'America/New_York',
        'hourly' => {
          'time' => ['2025-06-16T10:00', '2025-06-16T11:00'],
          'temperature_2m' => [22.1, 23.0],
          'rain' => [0.1, 0.0]
        },
        'daily' => {
          'time' => ['2025-06-16', '2025-06-17'],
          'temperature_2m_max' => [26.0, 28.5],
          'rain_sum' => [0.5, 0.0],
          'showers_sum' => [0.0, 0.0],
          'snowfall_sum' => [0.0, 0.0]
        },
        'current' => {
          'temperature_2m' => 23.5,
          'rain' => 0.0
        },
        'hourly_units' => { 'temperature_2m' => '°C', 'rain' => 'mm' },
        'daily_units' => { 'temperature_2m_max' => '°C', 'rain_sum' => 'mm' },
        'current_units' => { 'temperature_2m' => '°C' }
      }
    end

    let(:formatted_result_keys) { %w[current_weather daily_weather hourly_weather units timezone] }

    before do
      allow(Cache).to receive(:read).and_return(nil)
      allow(Cache).to receive(:write)
      allow(GeoCoder).to receive(:lookup).and_return(geo_data)
      allow(WeatherApi).to receive(:fetch).and_return(raw_weather)
    end

    it 'returns cached result if available' do
      cached = { 'foo' => 'bar' }
      allow(Cache).to receive(:read).with("latest_data/#{zip}").and_return(cached)

      result = described_class.call(zip)
      expect(result[:result]).to eq(cached)
      expect(result[:source]).to eq('cache')
    end

    it 'returns error if geocoding fails' do
      allow(Cache).to receive(:read).and_return(nil)
      allow(GeoCoder).to receive(:lookup).and_return(nil)

      result = described_class.call(zip)
      expect(result[:error]).to eq('Could not geocode zip')
      expect(result[:status]).to eq(:unprocessable_entity)
    end

    it 'calls weather API and formats data when cache is empty' do
      result = described_class.call(zip)

      expect(result[:result]).to be_a(Hash)
      expect(result[:result].keys.sort).to eq(formatted_result_keys.sort)
      expect(result[:source]).to eq('api')

      expect(Cache).to have_received(:write).with("latest_data/#{zip}", kind_of(Hash), 30.minutes)
    end

    it 'raises an error when hourly data is missing' do
      allow(WeatherApi).to receive(:fetch).and_return(raw_weather.merge('hourly' => nil))

      expect {
        described_class.call(zip)
      }.to raise_error("Problem fetching hourly forcast")
    end

    it 'raises an error when daily data is missing' do
      allow(WeatherApi).to receive(:fetch).and_return(raw_weather.merge('daily' => nil))

      expect {
        described_class.call(zip)
      }.to raise_error("Problem fetching daily forcast")
    end
    
  end
end