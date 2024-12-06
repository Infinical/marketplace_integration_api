module Marketplaces
  class MarketplaceA < BaseMarketplace
    def initialize
      super
      @connection.url_prefix = "http://localhost:3001/api/"
    end

    def create_listing(params)
      response = make_request(:post, "products", body: transform_params(params))

      result = handle_response(response, "Marketplace A create")

      if result.success?
        print(result.data)
        Result.new(
          success: true,
          data: {
            marketplace_id: result.data["id"],
            marketplace: "marketplace_a"
          }
        )
      else
        result
      end
    rescue RetryError => e
      print(e)
      Result.new(
        success: false,
        error: e.message,
        context: { marketplace: "marketplace_a" }
      )
    end

    private

    def transform_params(params)
      {
        name: params[:title],
        price: params[:price_cents],
        sku: params[:seller_sku]
      }
    end
  end
end
