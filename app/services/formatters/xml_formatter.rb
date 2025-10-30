class Formatters::XmlFormatter < Formatters::BaseFormatter
  def parse(request_body)
    parsed = Hash.from_xml(request_body).deep_symbolize_keys
    # Unwrap <request> wrapper if present, otherwise return parsed hash
    # This handles both <request><data>...</data></request> and <data>...</data>
    parsed.key?(:request) ? parsed[:request] : parsed
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
end
