class TransactionValidator
  VALID_STATUSES = [ "approved", "reversed", "refunded", "error" ].freeze
  PHONE_REGEX = /\A\d{10,15}\z/  # 10-15 digits only, no special characters

  class ValidationError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
      super("Validation failed: #{errors.keys.join(', ')}")
    end
  end

  def initialize(params)
    @params = params
    @errors = {}
  end

  def validate!
    validate_type
    validate_status
    validate_merchant
    validate_amount
    validate_customer_email
    validate_customer_phone

    raise ValidationError.new(@errors) if @errors.any?

    true
  end

  def valid?
    validate!
    true
  rescue ValidationError
    false
  end

  def errors
    validate! rescue nil
    @errors
  end

  private

  attr_reader :params

  def validate_type
    type = params[:type]
    return @errors[:type] = "Type is required" if type.blank?
    return if TransactionFactory::TYPES.include?(type.to_s.downcase)

    @errors[:type] = "Invalid transaction type: #{type}. Must be one of: #{TransactionFactory::TYPES.join(", ")}"
  end

  def validate_status
    status = params[:status]
    return if status.blank?
    return if VALID_STATUSES.include?(status.to_s.downcase)

    @errors[:status] = "Invalid status: #{status}. Must be one of: #{VALID_STATUSES.join(", ")}"
  end

  def validate_merchant
    merchant_id = params[:merchant_id]
    return @errors[:merchant_id] = "Merchant ID is required" if merchant_id.blank?

    merchant = Merchant.find_by(id: merchant_id)
    return @errors[:merchant_id] = "Merchant not found" if merchant.nil?
    @errors[:merchant_id] = "Merchant is not active" unless merchant.active?
  end

  def validate_amount
    # Reversals don't require/allow amount
    return if params[:type]&.downcase == "reversal"

    amount = params[:amount]
    return @errors[:amount] = "Amount is required" if amount.blank?
    return if amount.to_f > 0

    @errors[:amount] = "Amount must be greater than 0"
  end

  def validate_customer_email
    customer_email = params[:customer_email]
    return @errors[:customer_email] = "Customer email is required" if customer_email.blank?
    return if customer_email.match?(URI::MailTo::EMAIL_REGEXP)

    @errors[:customer_email] = "Customer email is invalid"
  end

  def validate_customer_phone
    customer_phone = params[:customer_phone]
    return if customer_phone.blank?
    return if customer_phone.to_s.match?(PHONE_REGEX)

    @errors[:customer_phone] = "Customer phone is invalid"
  end
end
