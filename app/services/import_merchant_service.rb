class ImportMerchantService
  attr_reader :row, :user, :errors

  def initialize(row, user)
    @row = row
    @user = user
    @errors = []
  end

  def call
    validate_row_data!
    create_merchant
  rescue ActiveRecord::RecordInvalid => e
    errors << e.message
    nil
  end

  private

  def validate_row_data!
    raise ArgumentError, "Row data cannot be blank" if row.blank?
    raise ArgumentError, "User cannot be blank" if user.blank?
    raise ArgumentError, "Merchant name is required" if row["merchant_name"].blank?
    raise ArgumentError, "Merchant email is required" if row["merchant_email"].blank?
  end

  def create_merchant
    Merchant.create!(
      user: user,
      name: row["merchant_name"],
      email: row["merchant_email"],
      description: row["merchant_description"],
      active: true
    )
  end
end
