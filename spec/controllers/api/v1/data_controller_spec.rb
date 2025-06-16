# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::DataController, type: :controller do
  describe 'GET #fetch_data' do
    it 'returns error for missing zip' do
      get :fetch_data, params: { zip: nil }, format: :json
      expect(response).to have_http_status(:bad_request)
    end
    # Add more tests for valid/invalid zip, rate limiting, etc.
  end
end
