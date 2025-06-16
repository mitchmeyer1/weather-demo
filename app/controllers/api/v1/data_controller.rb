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
        data[:result][:source] = data[:source]

        if data[:error]
          render json: { error: data[:error] }, status: data[:status] and return
        else
          render json: data[:result]
        end
      end
    end
  end
end