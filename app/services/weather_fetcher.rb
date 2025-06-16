class WeatherFetcher
  def self.call(zip)
    cached = Cache.read("latest_data/#{zip}")
    if cached
      return { result: cached }
    end

    geo = GeoCoder.lookup(zip)
    unless geo
      return { error: 'Could not geocode zip', status: :unprocessable_entity }
    end

    weather = WeatherApi.fetch(geo[:lat], geo[:lon], geo[:timezone_code])[0]

    # Format data to be easier to implement for front end clients
    weather['hourly_weather'] = hourly_weather(weather)
    weather['daily_weather'] = daily_weather(weather)
    weather['current_weather'] = weather['current']

    # Add in metric units to a simple key
    weather['units'] = ((weather['hourly_units']).deep_merge(weather['daily_units'])).deep_merge(weather['current_units'])

    # Return only helpful keys for front end clients, not everything from the weather API
    filtered_weather = weather.select { |k, _| ["current_weather", "daily_weather", "hourly_weather", "units", "timezone"].include?(k) }

    Cache.write("latest_data/#{zip}", filtered_weather, 30.minutes)

    { result: filtered_weather }
    end

    def self.hourly_weather(weather_json)
      return [] unless weather_json['hourly'] && weather_json['hourly']['time']

      hourly = weather_json['hourly']
      times = hourly['time']
      keys = hourly.keys - ['time']
      today = Time.now.utc.strftime('%Y-%m-%d')

      days_hash = {}
      times.each_with_index do |iso, i|
        day = iso[0,10] # 'YYYY-MM-DD'
        days_hash[day] ||= []
        hour_obj = { time: iso }
        keys.each do |key|
        hour_obj[key.to_sym] = hourly[key][i]
        end
        days_hash[day] << hour_obj
      end

      days_hash.map { |day, hours| { day: day, hours: hours } }
    end

    def self.daily_weather(weather_json)
      return [] unless weather_json['daily'] && weather_json['daily']['time']

      daily = weather_json['daily']
      times = daily['time']
      keys = daily.keys - ['time']

      days_hash = []
      today = Time.now.utc.strftime('%Y-%m-%d')
      times.each_with_index do |iso, i|
        day = iso[0,10] # 'YYYY-MM-DD'
        next if day < today

        day_obj = { time: iso }
        keys.each do |key|
          day_obj[key.to_sym] = daily[key][i]
        end

        max_key = [:rain_sum, :showers_sum, :snowfall_sum].max_by { |k| day_obj[k] }
        day_obj['precipitation_type'] = max_key.to_s.gsub('_sum', '') 

        days_hash << day_obj
      end


    days_hash
  end


end