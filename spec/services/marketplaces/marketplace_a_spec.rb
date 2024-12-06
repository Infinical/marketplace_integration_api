require 'rails_helper'

RSpec.describe Marketplaces::MarketplaceA do
  let(:marketplace) { described_class.new }
  let(:params) do
    {
      title: "Test Product",
      price_cents: 1999,
      seller_sku: "ABC123"
    }
  end

  describe '#create_listing' do
    context 'when the request succeeds' do
      before do
        stub_request(:post, "http://localhost:3001/api/products")
          .to_return(
            status: 201,
            body: { id: "12345", status: "success" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns a successful result' do
        result = marketplace.create_listing(params)
        expect(result.success?).to be true
        expect(result.data[:marketplace_id]).to eq("12345")
        expect(result.data[:marketplace]).to eq("marketplace_a")
      end
    end



    context 'when the request fails permanently' do
      before do
        stub_request(:post, "http://localhost:3001/api/products")
          .to_return(status: 500)
      end

      it 'returns a failure result' do
        result = marketplace.create_listing(params)
        expect(result.success?).to be false
      end
    end
  end
end
