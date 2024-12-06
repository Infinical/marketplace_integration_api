require 'rails_helper'

RSpec.describe Api::V1::ProductsController, type: :request do
  let(:valid_params) do
    {
      product: {
        title: "Test Product",
        price_cents: 1999,
        seller_sku: "ABC123"
      }
    }
  end

  describe 'POST /api/v1/products' do
    context 'when all marketplaces succeed' do
      before do
        stub_marketplace_a_success
        stub_marketplace_b_success
      end

      it 'returns success status with marketplace results' do
        post '/api/v1/products', params: valid_params
        print(response)
        expect(response).to have_http_status(:ok)
        expect(json_response[:status]).to eq('success')
      end
    end

    context 'when there are partial failures' do
      before do
        stub_marketplace_a_success
        stub_request(:post, "http://localhost:3002/inventory")
          .to_return(status: 500)
      end

      it 'returns partial content status with failure details' do
        post '/api/v1/products', params: valid_params

        expect(response).to have_http_status(:partial_content)
        expect(json_response[:status]).to eq('error')
        expect(json_response[:successful_marketplaces]).to include('Marketplaces::MarketplaceA')
      end
    end

    context 'when all marketplaces fail' do
      before do
        stub_request(:post, "http://localhost:3001/api/products")
          .to_return(status: 500)
        stub_request(:post, "http://localhost:3002/inventory")
          .to_return(status: 500)
      end

      it 'returns error status with failure details' do
        post '/api/v1/products', params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response[:status]).to eq('error')
      end
    end

    context 'with recoverable failures' do
      before do
        stub_marketplace_a_success
        stub_request(:post, "http://localhost:3002/inventory")
          .to_return(
            status: 200,
            body: { inventory_id: "67890" }.to_json,
            headers: { 'Content-Type': 'application/json' }
          )
        stub_request(:post, "http://localhost:3002/inventory/67890/publish")
          .to_return(status: 500)
      end

      it 'indicates recoverable status in response' do
        post '/api/v1/products', params: valid_params

        expect(response).to have_http_status(:partial_content)
        expect(json_response[:recoverable]).to be true
      end
    end
  end

  private

  def json_response
    @json_response ||= JSON.parse(response.body).deep_symbolize_keys
  end
end
