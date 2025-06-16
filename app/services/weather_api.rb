require 'net/http'
require 'uri'
require 'json'

# Service class for fetching weather data from Open Meteo API
# Provides detailed weather forecasts based on geographical coordinates
class WeatherApi
  # Fetches weather forecast data for given coordinates
  # @param lat [Float] Latitude (-90 to 90)
  # @param lon [Float] Longitude (-180 to 180)
  # @param timezone_code [String] IANA timezone identifier (e.g., "America/New_York")
  # @return [Hash] Weather forecast data including current, hourly, and daily forecasts
  def self.fetch(lat, lon, timezone_code)
    # Validate latitude range
    unless lat.to_s.match?(/\A-?\d+(\.\d+)?\z/) && lat.to_f.between?(-90, 90)
      raise "Invalid latitude: #{lat}"
    end

    # Validate longitude range
    unless lon.to_s.match?(/\A-?\d+(\.\d+)?\z/) && lon.to_f.between?(-180, 180)
      raise "Invalid longitude: #{lon}"
    end

    # Validate timezone format (e.g., "America/New_York")
    unless timezone_code.to_s.match?(/\A[A-Za-z_]+\/[A-Za-z_]+\z/)
      raise "Invalid timezone format: #{timezone_code}"
    end

    # Construct URL with all required weather parameters
    url = "https://api.open-meteo.com/v1/forecast?timezone=#{timezone_code}&latitude=#{lat}&longitude=#{lon}&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,rain_sum,snowfall_sum,showers_sum,precipitation_probability_max&hourly=temperature_2m,precipitation_probability,rain,showers,snowfall&current=rain,showers,snowfall,precipitation,temperature_2m,is_day,wind_speed_10m,wind_direction_10m"

    # Make API request and parse response
    uri = URI(url)
    res = Net::HTTP.get(uri)
    JSON.parse(res)
  end
end
