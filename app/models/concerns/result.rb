class Result
  attr_reader :success, :data, :error, :context

  def initialize(success:, data: {}, error: nil, context: {})
    @success = success
    @data = data
    @error = error
    @context = context
  end

  def success?
    @success
  end

  def failure?
    !success?
  end

  def merge_context(additional_context)
    @context.merge!(additional_context)
    self
  end
end
