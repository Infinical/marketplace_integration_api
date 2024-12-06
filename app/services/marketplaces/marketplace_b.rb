module Marketplaces
  class MarketplaceB < BaseMarketplace
    def initialize
      super
      @connection.url_prefix = "http://localhost:3002"
    end

    def create_listing(params)
      inventory_result = create_inventory_item(params)
      return inventory_result if inventory_result.failure?

      publish_result = publish_listing(inventory_result.data[:inventory_id])

      if publish_result.success?
        Result.new(
          success: true,
          data: {
            marketplace_id: publish_result.data[:listing_id],
            marketplace: "marketplace_b",
            inventory_id: inventory_result.data[:inventory_id]
          }
        )
      else
        Result.new(
          success: false,
          error: publish_result.error,
          context: {
            marketplace: "marketplace_b",
            inventory_id: inventory_result.data[:inventory_id],
            recoverable: true
          }
        )
      end
    end

    def retry_publish(inventory_id)
      publish_listing(inventory_id)
    end

    private

    def create_inventory_item(params)
      response = make_request(:post, "/inventory", body: transform_params(params))
      result = handle_response(response, "Marketplace B inventory creation")

      if result.success?
        Result.new(
          success: true,
          data: { inventory_id: result.data["inventory_id"] }
        )
      else
        result
      end
    rescue RetryError => e
      Result.new(
        success: false,
        error: e.message,
        context: { marketplace: "marketplace_b" }
      )
    end

    def publish_listing(inventory_id)
      response = make_request(:post, "/inventory/#{inventory_id}/publish")
      result = handle_response(response, "Marketplace B publish")

      if result.success?
        Result.new(
          success: true,
          data: { listing_id: result.data["listing_id"] }
        )
      else
        result
      end
    rescue RetryError => e
      Result.new(
        success: false,
        error: e.message,
        context: {
          marketplace: "marketplace_b",
          inventory_id: inventory_id,
          recoverable: true
        }
      )
    end

    def transform_params(params)
      {
        title: params[:title],
        price_cents: params[:price_cents],
        seller_sku: params[:seller_sku]
      }
    end
  end
end
