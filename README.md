# Weather API Service

A Ruby on Rails API service that provides weather data by ZIP code, featuring Redis-based caching and rate limiting.

## Technologies

- Ruby 3.2.8
- Rails 7.1.5
- Redis 7.x
- Docker & Docker Compose

## Features

- Weather data retrieval by ZIP code
- Redis-based caching
- Rate limiting by IP address
- Docker containerization
- RSpec testing suite

## Prerequisites

- Docker and Docker Compose
- Git

## Getting Started

1. Clone the repository:
   ```bash
   git clone git@github.com:mitchmeyer1/weather-demo.git
   cd aws_test_weather_app
   ```

2. Copy the environment file:
   ```bash
   cp .env.example .env
   ```

3. Build and start the services:
   ```bash
   docker-compose up --build
   ```

The application will be available at `http://localhost:3000`

## API Endpoints

### GET /api/v1/data

Retrieves weather data for a specified ZIP code.

**Parameters:**
- `zip` (required): A 5-digit US ZIP code

**Response Example:**
```json
    {
    "timezone": "America/New_York",
    "hourly_weather": [
        {
        "day": "2025-06-16",
        "hours": [
            {
            "time": "2025-06-16T00:00",
            "temperature_2m": 15.2,
            "precipitation_probability": 1,
            "rain": 0,
            "showers": 0,
            "snowfall": 0
            },
            {
            "time": "2025-06-16T01:00",
            "temperature_2m": 15,
            "precipitation_probability": 1,
            "rain": 0,
            "showers": 0,
            "snowfall": 0
            }
            ...
        ]
        },
        {
        "day": "2025-06-17",
        "hours": [
            {
            "time": "2025-06-17T00:00",
            "temperature_2m": 17.1,
            "precipitation_probability": 4,
            "rain": 0,
            "showers": 0,
            "snowfall": 0
            },
            {
            "time": "2025-06-17T01:00",
            "temperature_2m": 17,
            "precipitation_probability": 4,
            "rain": 0,
            "showers": 0,
            "snowfall": 0
            },
            ...
        ]
        },
        ...
    ],
    "daily_weather": [
        {
        "time": "2025-06-16",
        "temperature_2m_max": 19,
        "temperature_2m_min": 14.7,
        "sunrise": "2025-06-16T05:24",
        "sunset": "2025-06-16T20:28",
        "rain_sum": 0.2,
        "snowfall_sum": 0,
        "showers_sum": 0,
        "precipitation_probability_max": 15,
        "precipitation_type": "rain"
        },
        {
        "time": "2025-06-17",
        "temperature_2m_max": 20.1,
        "temperature_2m_min": 16.7,
        "sunrise": "2025-06-17T05:24",
        "sunset": "2025-06-17T20:29",
        "rain_sum": 0.4,
        "snowfall_sum": 0,
        "showers_sum": 0,
        "precipitation_probability_max": 16,
        "precipitation_type": "rain"
        },
        ...
    ],
    "current_weather": {
        "time": "2025-06-16T15:30",
        "interval": 900,
        "rain": 0,
        "showers": 0,
        "snowfall": 0,
        "precipitation": 0,
        "temperature_2m": 17.9,
        "is_day": 1,
        "wind_speed_10m": 11.9,
        "wind_direction_10m": 93
    },
    "units": {
        "time": "iso8601",
        "temperature_2m": "°C",
        "precipitation_probability": "%",
        "rain": "mm",
        "showers": "mm",
        "snowfall": "cm",
        "temperature_2m_max": "°C",
        "temperature_2m_min": "°C",
        "sunrise": "iso8601",
        "sunset": "iso8601",
        "rain_sum": "mm",
        "snowfall_sum": "cm",
        "showers_sum": "mm",
        "precipitation_probability_max": "%",
        "interval": "seconds",
        "precipitation": "mm",
        "is_day": "",
        "wind_speed_10m": "km/h",
        "wind_direction_10m": "°"
    },
    "source": "cache"
    }
```

**Error Responses:**
- 400: Missing or invalid ZIP code
- 429: Rate limit exceeded
- 500: Internal server error

## Development

### Running Tests

```bash
docker-compose run web bundle exec rspec
```

### Project Structure

- `app/controllers/api/v1/data_controller.rb` - Main API endpoint controller
- `app/services/weather_fetcher.rb` - Macro service that inputs zip and outputs formatted local weather data
- `app/services/weather_api.rb` - Retrieves weather data from source
- `app/services/geo_coder.rb` - Converts zipcode to lat/lon for the weather api
- `app/lib/cache.rb` - Redis cache interface for caching weather details by zip code with expiration
- `app/lib/rate_limiter.rb` - Rate limiting service preventing spamming from single IPs

## Docker Configurat## Docker Configuratludes:
- Web service (Rails application)
- Redis service

The docker-compThe donfiguration includes:
- Volume mounting for- Volume mounting forRedis persistence
- Automatic server restarting
- Gem caching

### Development Setup### Dash
# Run with rebuild (Use this first time on a new machine)
docker-compose up --build

# Start all services after build
docker-compose up

# Run in background
docker-compose up -d
```

### Testing
```bash
# Run the test suite
docker-compose run web bundle exec rspec

# Run specific tests
docker-compose run web bundle exec rspec path/to/spec
```

## Architectural Decisions

1. **Redis Integration**
   - Used for caching weather data
   - Implements rate limiting functionality
   - Configured for persistence

2. **Docker Implementation**
   - Multi-stage builds for production optimization
   - Development-friendly configuration with volume mounting
   - Separate services for application and Redis

3. **API Design**
   - RESTful endpoint structure
   - Comprehensive error handling
   - Rate limiting for API protection

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Create a Pull Request

