# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::DataController, type: :request do
  describe 'GET /api/v1/data' do
    let(:zip) { '11211' }
    let(:ip) { '1.2.3.4' }

    before do
      allow(RateLimiter).to receive(:allowed?).and_return(true)
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip).and_return(ip)
    end

    it 'returns 200 and weather data for valid zip' do
      weather_data = {
        result: {
          current_weather: {},
          daily_weather: [],
          hourly_weather: [],
          units: {},
          timezone: 'America/New_York'
        },
        source: 'api'
      }

      allow(WeatherFetcher).to receive(:call).with(zip).and_return(weather_data)

      get '/api/v1/data', params: { zip: zip }

      expect(response).to have_http_status(:ok)
      parsed = JSON.parse(response.body)
      expect(parsed['source']).to eq('api')
      expect(parsed).to include('current_weather', 'daily_weather', 'hourly_weather', 'units', 'timezone')
    end

    it 'returns 400 for missing or invalid zip' do
      get '/api/v1/data', params: { zip: 'abc' }

      expect(response).to have_http_status(:bad_request)
      expect(JSON.parse(response.body)).to eq({ 'error' => 'Missing or invalid zip parameter' })
    end

    it 'returns 429 if rate limit exceeded' do
      allow(RateLimiter).to receive(:allowed?).with(ip).and_return(false)

      get '/api/v1/data', params: { zip: zip }

      expect(response).to have_http_status(:too_many_requests)
      expect(JSON.parse(response.body)).to eq({ 'error' => 'Rate limit exceeded. Please try again after 30 seconds.' })
    end

    it 'returns 422 if WeatherFetcher returns an error' do
      allow(WeatherFetcher).to receive(:call).with(zip).and_return({
        error: 'Could not geocode zip',
        status: :unprocessable_entity
      })

      get '/api/v1/data', params: { zip: zip }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)).to eq({ 'error' => 'Could not geocode zip' })
    end

    it 'returns 500 if WeatherFetcher raises an unexpected error' do
      allow(WeatherFetcher).to receive(:call).with(zip).and_raise("Unexpected failure")

      expect {
        get '/api/v1/data', params: { zip: zip }
      }.to raise_error(RuntimeError, "Unexpected failure")
    end
  end
end