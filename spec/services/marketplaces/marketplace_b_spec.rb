require 'rails_helper'

RSpec.describe Marketplaces::MarketplaceB do
  let(:marketplace) { described_class.new }
  let(:params) do
    {
      title: "Test Product",
      price_cents: 1999,
      seller_sku: "ABC123"
    }
  end

  describe '#create_listing' do
    context 'when both steps succeed' do
      before do
        stub_request(:post, "http://localhost:3002/inventory")
          .to_return(
            status: 200,
            body: { inventory_id: "67890", status: "created" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:post, "http://localhost:3002/inventory/67890/publish")
          .to_return(
            status: 200,
            body: { listing_id: "L123", status: "published" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'returns a successful result' do
        result = marketplace.create_listing(params)
        expect(result.success?).to be true
        expect(result.data[:marketplace_id]).to eq("L123")
        expect(result.data[:marketplace]).to eq("marketplace_b")
        expect(result.data[:inventory_id]).to eq("67890")
      end
    end

    context 'when inventory creation succeeds but publishing fails' do
      before do
        stub_request(:post, "http://localhost:3002/inventory")
          .to_return(
            status: 200,
            body: { inventory_id: "67890", status: "created" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        stub_request(:post, "http://localhost:3002/inventory/67890/publish")
          .to_return(status: 500)
      end

      it 'returns a failure result with recoverable context' do
        result = marketplace.create_listing(params)
        expect(result.success?).to be false
        expect(result.context[:recoverable]).to be true
        expect(result.context[:inventory_id]).to eq("67890")
      end
    end

    context 'when inventory creation fails permanently' do
      before do
        stub_request(:post, "http://localhost:3002/inventory")
          .to_return(status: 500)
      end

      it 'returns a failure result' do
        result = marketplace.create_listing(params)
        expect(result.success?).to be false
        expect(result.context[:recoverable]).to be_nil
      end
    end
  end

  describe '#retry_publish' do
    let(:inventory_id) { "67890" }

    context 'when retry succeeds' do
      before do
        stub_request(:post, "http://localhost:3002/inventory/#{inventory_id}/publish")
          .to_return(
            status: 200,
            body: { listing_id: "L123", status: "published" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'successfully publishes the listing' do
        result = marketplace.retry_publish(inventory_id)
        expect(result.success?).to be true
        expect(result.data[:listing_id]).to eq("L123")
      end
    end

    context 'when retry fails after multiple attempts' do
      before do
        stub_request(:post, "http://localhost:3002/inventory/#{inventory_id}/publish")
          .to_return(status: 500)
      end

      it 'returns a failure result with recoverable context' do
        result = marketplace.retry_publish(inventory_id)
        expect(result.success?).to be false
        expect(result.context[:recoverable]).to be true
      end
    end
  end
end
