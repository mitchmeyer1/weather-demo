class WeatherApi
  def self.fetch(lat, lon, timezone_code)
    url = "https://api.open-meteo.com/v1/forecast?timezone=#{timezone_code}&latitude=#{lat}&longitude=#{lon}&latitude=52.52&longitude=13.41&daily=temperature_2m_max,temperature_2m_min,sunrise,sunset,rain_sum,snowfall_sum,showers_sum,precipitation_probability_max&hourly=temperature_2m,precipitation_probability,rain,showers,snowfall&current=rain,showers,snowfall,precipitation,temperature_2m,is_day,wind_speed_10m,wind_direction_10m"

    uri = URI(url)
    res = Net::HTTP.get(uri)
    JSON.parse(res)
  end
end

