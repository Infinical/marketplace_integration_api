module Marketplaces
  class BaseMarketplace
    include Loggable
    include Retryable

    RETRY_OPTIONS = {
      max_attempts: 3,
      delay: 2
    }

    def initialize
      @connection = Faraday.new do |faraday|
        faraday.request :json
        faraday.response :json
        faraday.adapter Faraday.default_adapter
      end
    end

    def create_listing(params)
      raise NotImplementedError
    end

    protected

    def handle_response(response, operation_name)
      case response.status
      when 200, 201
        Result.new(success: true, data: response.body)
      else
        log_error("#{operation_name} failed with status #{response.status}")
        Result.new(
          success: false,
          error: "#{operation_name} failed with status #{response.status}",
          context: { status_code: response.status }
        )
      end
    end

    private

    def make_request(method, url, options = {})
      with_retry(RETRY_OPTIONS) do
        @connection.send(method) do |req|
          req.url url
          req.headers.merge!(options[:headers] || {})
          req.body = options[:body] if options[:body]
        end
      end
    end
  end
end
