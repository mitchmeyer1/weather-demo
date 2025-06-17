# Service class responsible for orchestrating weather data retrieval.
# Handles caching, geocoding, and weather API interactions.
class WeatherFetcher
  # Fetches weather data for a given ZIP code
  # @param zip [String] 5-digit US ZIP code
  # @return [Hash] Weather data with source information or error details
  def self.call(zip)
    # Try to fetch data from cache first
    cached = Cache.read("latest_data/#{zip}")
    if cached
      return { result: cached, source: 'cache' }
    end

    # If not in cache, get coordinates from ZIP code
    geo = GeoCoder.lookup(zip)
    unless geo
      return { error: 'Could not geocode zip', status: :unprocessable_entity }
    end

    # Fetch weather data using coordinates
    weather = WeatherApi.fetch(geo[:lat], geo[:lon], geo[:timezone_code])


    # Format data for frontend consumption
    weather['hourly_weather'] = hourly_weather(weather)
    weather['daily_weather'] = daily_weather(weather)
    weather['current_weather'] = weather['current']

    # Consolidate unit information
    weather['units'] = ((weather['hourly_units']).deep_merge(weather['daily_units'])).deep_merge(weather['current_units'])

    # Filter only necessary data for frontend
    filtered_weather = weather.select { |k, _| ["current_weather", "daily_weather", "hourly_weather", "units", "timezone"].include?(k) }

    # Cache the processed data
    Cache.write("latest_data/#{zip}", filtered_weather, 30.minutes)

    { result: filtered_weather, source: 'api'  }
    end

    # Processes and formats hourly weather data
    # @param weather_json [Hash] Raw weather API response
    # @return [Array<Hash>] Formatted hourly weather data grouped by day
    def self.hourly_weather(weather_json)
      raise "Problem fetching hourly forcast" unless weather_json['hourly'] && weather_json.dig('hourly', 'time')

      # Extract hourly data and group by day

      hourly = weather_json['hourly']
      times = hourly['time']
      keys = hourly.keys - ['time']
      today = Time.now.utc.strftime('%Y-%m-%d')

      # Group hourly data by day
      days_hash = {}
      times.each_with_index do |iso, i|
        day = iso[0,10] # Extract YYYY-MM-DD from timestamp
        days_hash[day] ||= []
        hour_obj = { time: iso }
        keys.each do |key|
        hour_obj[key.to_sym] = hourly[key][i]
        end
        days_hash[day] << hour_obj
      end

      days_hash.map { |day, hours| { day: day, hours: hours } }
    end

    # Processes and formats daily weather data
    # @param weather_json [Hash] Raw weather API response
    # @return [Array<Hash>] Formatted daily weather data
    def self.daily_weather(weather_json)
       raise "Problem fetching daily forcast" unless weather_json['daily'] && weather_json['daily']['time']

      daily = weather_json['daily']
      times = daily['time']
      keys = daily.keys - ['time']

      days_hash = []
      today = Time.now.utc.strftime('%Y-%m-%d')
      times.each_with_index do |iso, i|
        day = iso[0,10] # Extract YYYY-MM-DD from timestamp
        next if day < today

        # Build daily weather object
        day_obj = { time: iso }
        keys.each do |key|
          day_obj[key.to_sym] = daily[key][i]
        end

        # Determine predominant precipitation type
        max_key = [:rain_sum, :showers_sum, :snowfall_sum].max_by { |k| day_obj[k] }
        day_obj['precipitation_type'] = max_key.to_s.gsub('_sum', '') 

        days_hash << day_obj
      end


    days_hash
  end


end
