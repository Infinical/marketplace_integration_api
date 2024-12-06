module Validators
  class ProductParamsValidator
    include Loggable

    REQUIRED_FIELDS = [:title, :price_cents, :seller_sku]
    
    VALIDATIONS = {
      title: {
        presence: true,
        length: { minimum: 3, maximum: 255 },
        format: { pattern: /\A[a-zA-Z0-9\s\-_]+\z/, message: "can only contain letters, numbers, spaces, hyphens and underscores" }
      },
      price_cents: {
        presence: true,
        numericality: { 
          only_integer: true,
          greater_than: 0,
          less_than: 1_000_000_00  # $1,000,000 in cents
        }
      },
      seller_sku: {
        presence: true,
        length: { minimum: 3, maximum: 50 },
        format: { pattern: /\A[A-Z0-9\-_]+\z/, message: "can only contain uppercase letters, numbers, hyphens and underscores" }
      }
    }

    def initialize(params)
      @params = params
      @errors = []
    end

    def validate
      return missing_params_result if missing_required_params?
      
      validate_all_fields
      
      if @errors.empty?
        Result.new(success: true, data: @params)
      else
        log_validation_errors
        Result.new(
          success: false,
          error: "Validation failed",
          data: { errors: @errors },
          context: { validation: 'product_params' }
        )
      end
    end

    private

    def missing_required_params?
      REQUIRED_FIELDS.any? { |field| @params[field].nil? }
    end

    def missing_params_result
      missing_fields = REQUIRED_FIELDS.select { |field| @params[field].nil? }
      Result.new(
        success: false,
        error: "Missing required fields",
        data: { missing_fields: missing_fields },
        context: { validation: 'product_params' }
      )
    end

    def validate_all_fields
      VALIDATIONS.each do |field, rules|
        validate_field(field, rules) if @params[field]
      end
    end

    def validate_field(field, rules)
      rules.each do |rule_type, rule_value|
        case rule_type
        when :presence
          validate_presence(field, rule_value)
        when :length
          validate_length(field, rule_value)
        when :format
          validate_format(field, rule_value)
        when :numericality
          validate_numericality(field, rule_value)
        end
      end
    end

    def validate_presence(field, _rule)
      if @params[field].to_s.strip.empty?
        add_error(field, "cannot be empty")
      end
    end

    def validate_length(field, rules)
      value = @params[field].to_s
      
      if rules[:minimum] && value.length < rules[:minimum]
        add_error(field, "is too short (minimum is #{rules[:minimum]} characters)")
      end
      
      if rules[:maximum] && value.length > rules[:maximum]
        add_error(field, "is too long (maximum is #{rules[:maximum]} characters)")
      end
    end

    def validate_format(field, rule)
      unless @params[field].to_s.match?(rule[:pattern])
        add_error(field, rule[:message])
      end
    end

    def validate_numericality(field, rules)
      value = @params[field]
      
      unless value.is_a?(Integer)
        add_error(field, "must be an integer")
        return
      end

      if rules[:greater_than] && value <= rules[:greater_than]
        add_error(field, "must be greater than #{rules[:greater_than]}")
      end

      if rules[:less_than] && value >= rules[:less_than]
        add_error(field, "must be less than #{rules[:less_than]}")
      end
    end

    def add_error(field, message)
      @errors << { field: field, message: message }
    end

    def log_validation_errors
      log_error(
        "Product params validation failed",
        nil,
        {
          errors: @errors,
          params: @params.except(:password, :secret)  # Don't log sensitive data
        }
      )
    end
  end
end