require 'net/http'
require 'uri'
require 'json'

class GeoCoder
  def self.lookup(zip)
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