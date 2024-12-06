module Loggable
  def log_info(message, context = {})
    Rails.logger.info(format_log_message("INFO", message, context))
  end

  def log_error(message, error = nil, context = {})
    error_context = error ? { error_class: error.class.name, error_message: error.message } : {}
    Rails.logger.error(format_log_message("ERROR", message, context.merge(error_context)))
  end

  def log_retry(message, attempt, max_attempts, context = {})
    retry_context = { attempt: attempt, max_attempts: max_attempts }
    Rails.logger.info(format_log_message("RETRY", message, context.merge(retry_context)))
  end

  private

  def format_log_message(level, message, context)
    timestamp = Time.current.iso8601
    service_name = self.class.name
    context_str = context.map { |k, v| "#{k}=#{v}" }.join(" ")

    "[#{timestamp}] [#{level}] [#{service_name}] #{message} #{context_str}"
  end
end
