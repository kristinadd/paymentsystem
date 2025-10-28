class ImportUserService
  attr_reader :row, :errors

  def initialize(row)
    @row = row
    @errors = []
  end

  def call
    validate_row_data!
    create_user
  rescue ActiveRecord::RecordInvalid => e
    errors << e.message
    nil
  end

  private

  def validate_row_data!
    raise ArgumentError, "Row data cannot be blank" if row.blank?
    raise ArgumentError, "Name is required" if row["name"].blank?
    raise ArgumentError, "Email is required" if row["email"].blank?
    raise ArgumentError, "Role is required" if row["role"].blank?
  end

  def create_user
    User.create!(
      name: row["name"],
      email: row["email"],
      role: row["role"]
    )
  end
end
