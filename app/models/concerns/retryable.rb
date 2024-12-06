module Retryable
  class RetryError < StandardError; end

  def with_retry(options = {})
    attempt = 1
    max_attempts = options.fetch(:max_attempts, 3)
    delay = options.fetch(:delay, 2)
    operation_name = options.fetch(:operation_name, "operation")

    begin
      log_info("Starting #{operation_name}", attempt: attempt)
      result = yield
      log_info("#{operation_name} completed successfully", attempt: attempt)
      result
    rescue => e
      log_error("#{operation_name} failed", e, attempt: attempt)

      if attempt < max_attempts
        log_retry("Retrying #{operation_name}", attempt, max_attempts)
        sleep(delay)
        attempt += 1
        retry
      else
        log_error("#{operation_name} failed permanently after #{max_attempts} attempts")
        raise RetryError, "Max retries (#{max_attempts}) exceeded: #{e.message}"
      end
    end
  end
end
