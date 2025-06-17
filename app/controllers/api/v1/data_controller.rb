module Api
  module V1
    # Controller handling weather data API requests.
    # Provides endpoints for fetching weather information based on ZIP codes.
    class DataController < ApplicationController
      
      # GET /api/v1/data/fetch_data
      # Fetches weather data for a given ZIP code with rate limiting and caching
      # @param zip [String] 5-digit US ZIP code
      # @return [JSON] Weather data or error message
      def fetch_data
        zip = params[:zip]
        # Validate ZIP code format (must be 5 digits)
        unless zip.present? && zip.match?(/^\d{5}$/)
          render json: { error: 'Missing or invalid zip parameter' }, status: :bad_request and return
        end

        # Check rate limiting based on client IP
        ip = request.remote_ip
        unless RateLimiter.allowed?(ip)
          render json: { error: 'Rate limit exceeded. Please try again after 30 seconds.' }, status: :too_many_requests and return
        end

        # Fetch weather data using the WeatherFetcher service
        data = WeatherFetcher.call(zip)

        # Handle error responses from the weather service
        if data[:error]
          render json: { error: data[:error] }, status: data[:status] and return
        else
          begin 
            # Add data source information (cache or API) to the response
            data[:result][:source] = data[:source]
            render json: data[:result]
          rescue => e 
            render json: { error: 'unknown server error' }, status: :internal_server_error
          end
        end
      end
    end
  end
end
