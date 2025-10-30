class Formatters::JsonFormatter < Formatters::BaseFormatter
  def parse(request_body)
    JSON.parse(request_body).deep_symbolize_keys
  rescue JSON::ParserError => e
    raise ActionController::BadRequest, "Invalid JSON: #{e.message}"
  end

  def serialize(transaction)
    {
      data: transaction_to_hash(transaction)
    }.to_json
  end

  def serialize_error(errors)
    error_hash = format_errors(errors)
    error_hash.to_json
  end

  def content_type
    "application/json"
  end
end
