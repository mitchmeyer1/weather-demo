require 'net/http'
require 'uri'
require 'json'

# Service class for converting ZIP codes to geographical coordinates
# Uses Open Meteo's geocoding service for location lookup
class GeoCoder
  # Looks up geographical coordinates for a given ZIP code
  # @param zip [String] 5-digit US ZIP code
  # @return [Hash, nil] Hash containing latitude, longitude, and timezone, or nil if lookup fails
  def self.lookup(zip)
    # Validate zip code format (must be 5 digits)
    unless zip.present? && zip.match?(/^\d{5}$/)
      puts "Invalid zip format: #{zip}"
      raise "Invalid zip format: #{zip}"
      return nil
    end

    # Make the API request to Open Meteo's geocoding service
    puts "Fetching geocoding data for zip: #{zip}"
    uri = URI("https://geocoding-api.open-meteo.com/v1/search?name=#{zip}&country=US")
    res = Net::HTTP.get(uri)
    data = JSON.parse(res)
    puts "Geocoding response for zip #{zip}:"
    puts data.inspect

    # Return nil if no results found
    return nil if data['results'].blank?

    # Return coordinates and timezone information
    {
      lat: data['results'][0]['latitude'],
      lon: data['results'][0]['longitude'],
      timezone_code: data['results'][0]['timezone']
    }
  end
end
