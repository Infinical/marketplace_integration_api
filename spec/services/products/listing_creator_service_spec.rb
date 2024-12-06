require 'rails_helper'

RSpec.describe Products::ListingCreatorService do
  let(:valid_params) do
    {
      title: "Test Product",
      price_cents: 1999,
      seller_sku: "ABC123"
    }
  end

  let(:service) { described_class.new(valid_params) }

  describe '#call' do
    context 'when all marketplaces succeed' do
      before do
        stub_marketplace_a_success
        stub_marketplace_b_success
      end

      it 'returns a successful result' do
        result = service.call
        expect(result.success?).to be true
        expect(result.data[:marketplace_results].keys).to match_array([
          'Marketplaces::MarketplaceA',
          'Marketplaces::MarketplaceB'
        ])
      end

      it 'logs success for each marketplace' do
        expect(Rails.logger).to receive(:info).with(/Successfully created listing/).twice
        service.call
      end
    end

    context 'when there are partial failures' do
      before do
        stub_marketplace_a_success
        stub_marketplace_b_failure
      end

      it 'returns a failure result with partial success context' do
        result = service.call
        expect(result.success?).to be false
        expect(result.context[:partial_success]).to be true
        expect(result.data[:successful_marketplaces]).to eq([ 'Marketplaces::MarketplaceA' ])
      end

      it 'includes recoverable status for marketplace B failure' do
        result = service.call
        expect(result.context[:recoverable_failures]).to be true
      end
    end

    context 'when all marketplaces fail' do
      before do
        stub_marketplace_a_failure
        stub_marketplace_b_failure
      end

      it 'returns a failure result' do
        result = service.call
        expect(result.success?).to be false
        expect(result.context[:partial_success]).to be false
      end

      it 'logs errors for each marketplace' do
        expect(Rails.logger).to receive(:error).with(/Failed to create listing/).twice
        service.call
      end
    end
  end

  describe '#retry_failed_publish' do
    context 'when retrying marketplace B publish' do
      let(:inventory_id) { "67890" }

      context 'when retry succeeds' do
        before { stub_marketplace_b_publish_success(inventory_id) }

        it 'successfully publishes the listing' do
          result = service.retry_failed_publish(
            marketplace: 'marketplace_b',
            inventory_id: inventory_id
          )
          expect(result.success?).to be true
          expect(result.data[:listing_id]).to be_present
        end
      end

      context 'when retry fails' do
        before { stub_marketplace_b_publish_failure(inventory_id) }

        it 'returns a failure result with recoverable context' do
          result = service.retry_failed_publish(
            marketplace: 'marketplace_b',
            inventory_id: inventory_id
          )
          expect(result.success?).to be false
          expect(result.context[:recoverable]).to be true
        end
      end
    end
  end

  private

  def stub_marketplace_a_success
    stub_request(:post, "http://localhost:3001/api/products")
      .to_return(
        status: 201,
        body: { id: "12345", status: "success" }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_marketplace_a_failure
    stub_request(:post, "http://localhost:3001/api/products")
      .to_return(status: 500)
  end

  def stub_marketplace_b_success
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

  def stub_marketplace_b_failure
    stub_request(:post, "http://localhost:3002/inventory")
      .to_return(status: 500)
  end

  def stub_marketplace_b_publish_success(inventory_id)
    stub_request(:post, "http://localhost:3002/inventory/#{inventory_id}/publish")
      .to_return(
        status: 200,
        body: { listing_id: "L123", status: "published" }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  def stub_marketplace_b_publish_failure(inventory_id)
    stub_request(:post, "http://localhost:3002/inventory/#{inventory_id}/publish")
      .to_return(status: 500)
  end
end
