require "csv"

class ImportUsersAndMerchantsOrchestrator
  attr_reader :file_path, :results

  def initialize(file_path)
    @file_path = file_path
    @results = {
      users_created: 0,
      merchants_created: 0,
      users_failed: 0,
      merchants_failed: 0,
      errors: []
    }
  end

  def import
    validate_file!
    process_csv
    self
  end

  def success?
    results[:users_failed] == 0 && results[:merchants_failed] == 0
  end

  def summary
    <<~SUMMARY
      ✅ Users created: #{results[:users_created]}
      ✅ Merchants created: #{results[:merchants_created]}
      ❌ Users failed: #{results[:users_failed]}
      ❌ Merchants failed: #{results[:merchants_failed]}
      📊 Total rows processed: #{total_rows_processed}
    SUMMARY
  end

  def error_report
    return "No errors! 🎉" if results[:errors].empty?

    report = "Errors:\n"
    results[:errors].each_with_index do |error, index|
      report += "#{index + 1}. #{error}\n"
    end
    report
  end

  private

  def validate_file!
    raise ArgumentError, "File path cannot be blank" if file_path.blank?
    raise ArgumentError, "File not found: #{file_path}" unless File.exist?(file_path)
  end

  def process_csv
    CSV.foreach(file_path, headers: true).with_index(2) do |row, line_number|
      process_row(row, line_number)
    end
  rescue ArgumentError => e
    # CSV structure error - stop processing
    results[:errors] << "CSV structure error at line #{line_number}: #{e.message}"
    raise
  end

  def process_row(row, line_number)
    user = import_user(row, line_number)
    return unless user

    import_merchant(row, user, line_number) if merchant_role?(row)
  end

  def import_user(row, line_number)
    user_service = ImportUserService.new(row)
    user = user_service.call

    if user
      results[:users_created] += 1
    else
      results[:users_failed] += 1
      results[:errors] << "Line #{line_number}: User creation failed - #{user_service.errors.join(', ')}"
    end

    user
  end

  def import_merchant(row, user, line_number)
    return unless has_merchant_data?(row)

    merchant_service = ImportMerchantService.new(row, user)
    merchant = merchant_service.call

    if merchant
      results[:merchants_created] += 1
    else
      results[:merchants_failed] += 1
      results[:errors] << "Line #{line_number}: Merchant creation failed - #{merchant_service.errors.join(', ')}"
    end
  end

  def merchant_role?(row)
    row["role"] == "merchant"
  end

  def has_merchant_data?(row)
    row["merchant_name"].present? || row["merchant_email"].present?
  end

  def total_rows_processed
    results[:users_created] + results[:users_failed]
  end
end
