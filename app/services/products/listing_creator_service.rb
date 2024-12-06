module Products
  class ListingCreatorService
    include Loggable

    def initialize(params)
      @params = params
      @marketplaces = [
        Marketplaces::MarketplaceA.new,
        Marketplaces::MarketplaceB.new
      ]
      @results = {}
    end

    def call
      validate_params
      return @validation_result if @validation_result&.failure?

      create_listings
      aggregate_results
    end

    def retry_failed_publish(marketplace:, inventory_id:)
      case marketplace
      when "marketplace_b"
        Marketplaces::MarketplaceB.new.retry_publish(inventory_id)
      else
        Result.new(
          success: false,
          error: "Unsupported marketplace for retry: #{marketplace}"
        )
      end
    end

    private

    def validate_params
      validator = ProductParamsValidator.new(@params)
      @validation_result = validator.validate
    end

    def create_listings
      @marketplaces.each do |marketplace|
        result = marketplace.create_listing(@params)
        @results[marketplace.class.name] = result

        log_marketplace_result(marketplace.class.name, result)
      end
    end

    def aggregate_results
      successes = @results.select { |_, r| r.success? }
      failures = @results.select { |_, r| r.failure? }

      if failures.empty?
        Result.new(
          success: true,
          data: { marketplace_results: @results }
        )
      else
        handle_partial_failure(successes, failures)
      end
    end

    def handle_partial_failure(successes, failures)
      Result.new(
        success: false,
        error: "Some marketplaces failed",
        data: {
          successful_marketplaces: successes.keys,
          failed_marketplaces: failures.transform_values { |r| r.error }
        },
        context: {
          partial_success: successes.any?,
          recoverable_failures: failures.values.any? { |r| r.context[:recoverable] }
        }
      )
    end

    def log_marketplace_result(marketplace, result)
      if result.success?
        log_info("Successfully created listing",
          marketplace: marketplace,
          marketplace_id: result.data[:marketplace_id]
        )
      else
        log_error("Failed to create listing",
          nil,
          marketplace: marketplace,
          error: result.error,
          context: result.context
        )
      end
    end
  end
end
