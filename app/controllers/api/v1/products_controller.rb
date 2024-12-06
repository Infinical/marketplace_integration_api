module Api
  module V1
    class ProductsController < ApplicationController
      def create
        result = Products::ListingCreatorService.new(product_params).call

        print(result.data)

        if result.success?
          render_success(result)
        else
          render_error(result)
        end
      end

      private

      def product_params
        params.require(:product).permit(:title, :price_cents, :seller_sku)
      end

      def render_success(result)
        render json: {
          status: "success",
          marketplace_results: result.data[:marketplace_results].transform_keys { |k| k.split("::").last.downcase }
        }, status: :ok
      end

      def render_error(result)
        status = result.context[:partial_success] ? :partial_content : :unprocessable_entity

        render json: {
          status: "error",
          error: result.error,
          failed_marketplaces: result.data[:failed_marketplaces],
          successful_marketplaces: result.data[:successful_marketplaces],
          recoverable: result.context[:recoverable_failures]
        }, status: status
      end
    end
  end
end
