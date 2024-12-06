require 'rails_helper'

RSpec.describe Validators::ProductParamsValidator do
  let(:valid_params) do
    {
      title: "Test Product",
      price_cents: 1999,
      seller_sku: "TEST123"
    }
  end

  describe '#validate' do
    context 'with valid params' do
      it 'returns success result' do
        result = described_class.new(valid_params).validate
        expect(result.success?).to be true
      end
    end

    context 'with missing params' do
      it 'returns failure result with missing fields' do
        params = valid_params.except(:title)
        result = described_class.new(params).validate

        expect(result.success?).to be false
        expect(result.data[:missing_fields]).to include(:title)
      end
    end

    context 'with invalid title' do
      it 'validates title format' do
        params = valid_params.merge(title: "Invalid@Title!")
        result = described_class.new(params).validate

        expect(result.success?).to be false
        expect(result.data[:errors]).to include(
          hash_including(
            field: :title,
            message: "can only contain letters, numbers, spaces, hyphens and underscores"
          )
        )
      end

      it 'validates title length' do
        params = valid_params.merge(title: "ab")
        result = described_class.new(params).validate

        expect(result.success?).to be false
        expect(result.data[:errors]).to include(
          hash_including(
            field: :title,
            message: "is too short (minimum is 3 characters)"
          )
        )
      end
    end

    context 'with invalid price_cents' do
      it 'validates price is positive' do
        params = valid_params.merge(price_cents: 0)
        result = described_class.new(params).validate

        expect(result.success?).to be false
        expect(result.data[:errors]).to include(
          hash_including(
            field: :price_cents,
            message: "must be greater than 0"
          )
        )
      end

      it 'validates price is not too high' do
        params = valid_params.merge(price_cents: 1_000_000_00)
        result = described_class.new(params).validate

        expect(result.success?).to be false
        expect(result.data[:errors]).to include(
          hash_including(
            field: :price_cents,
            message: "must be less than 100000000"
          )
        )
      end
    end

    context 'with invalid seller_sku' do
      it 'validates SKU format' do
        params = valid_params.merge(seller_sku: "invalid-sku!")
        result = described_class.new(params).validate

        expect(result.success?).to be false
        expect(result.data[:errors]).to include(
          hash_including(
            field: :seller_sku,
            message: "can only contain uppercase letters, numbers, hyphens and underscores"
          )
        )
      end
    end
  end
end
