require 'net/http'
require 'uri'
require 'json'

class GeoCoder
  def self.lookup(zip)
    # Validate zip code format
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

    # Check if the response contains results

    return nil if data['results'].blank?

    {
      lat: data['results'][0]['latitude'],
      lon: data['results'][0]['longitude'],
      timezone_code: data['results'][0]['timezone']
    }
  end
end