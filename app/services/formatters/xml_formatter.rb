class Formatters::XmlFormatter < Formatters::BaseFormatter
  def parse(request_body)
    parsed = Hash.from_xml(request_body).deep_symbolize_keys
    parsed.values.first.is_a?(Hash) ? parsed.values.first : parsed
  rescue REXML::ParseException => e
    raise ActionController::BadRequest, "Invalid XML: #{e.message}"
  end

  def serialize(transaction)
    hash = { data: transaction_to_hash(transaction) }
    hash.to_xml(root: "response", skip_types: true, skip_instruct: false)
  end

  def serialize_error(errors)
    error_hash = format_errors(errors)
    error_hash.to_xml(root: "response", skip_types: true, skip_instruct: false)
  end

  def content_type
    "application/xml"
  end

  private

  def format_errors(errors)
    case errors
    when Hash
      { errors: errors }
    when ActiveModel::Errors
      { errors: errors.messages }
    when String
      { error: errors }
    else
      { error: errors.to_s }
    end
  end
end
