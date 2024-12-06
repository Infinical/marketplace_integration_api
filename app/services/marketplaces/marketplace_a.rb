module Marketplaces
  class MarketplaceA < BaseMarketplace
    base_uri 'http://localhost:3001/api'

    def create_listing(params)
      with_retry(operation_name: 'marketplace_a_create') do
        response = self.class.post('/products', body: transform_params(params))
        result = handle_response(response, 'Marketplace A create')
        
        if result.success?
          Result.new(
            success: true,
            data: {
              marketplace_id: result.data['id'],
              marketplace: 'marketplace_a'
            }
          )
        else
          result
        end
      end
    rescue RetryError => e
      Result.new(success: false, error: e.message, context: { marketplace: 'marketplace_a' })
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