module Api
  module V1
    class DataController < ApplicationController
      def fetch_data
        zip = params[:zip]
        unless zip.present? && zip.match?(/^\d{5}$/)
          render json: { error: 'Missing or invalid zip parameter' }, status: :bad_request and return
        end

        ip = request.remote_ip
        unless RateLimiter.allowed?(ip)
          render json: { error: 'Rate limit exceeded. Please try again after 30 seconds.' }, status: :too_many_requests and return
        end

        data = WeatherFetcher.call(zip)

        if data[:error]
          render json: { error: data[:error] }, status: data[:status] and return
        else
          begin 
            data[:result][:source] = data[:source]
            render json: data[:result]
          rescue e 
            render json: { error: 'unknown server error' }, status: :internal_server_error
          end
        end
      end
    end
  end
end