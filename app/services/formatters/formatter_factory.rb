class Formatters::FormatterFactory
  FORMATTERS = {
    "application/json" => Formatters::JsonFormatter,
    "application/xml" => Formatters::XmlFormatter,
    "text/xml" => Formatters::XmlFormatter
  }.freeze

  def self.for_request(request)
    for_content_type(request.content_type)
  end

  def self.for_content_type(content_type)
    formatter_class = FORMATTERS[content_type]

    unless formatter_class
      supported = FORMATTERS.keys.join(", ")
      raise ActionController::BadRequest,
            "Unsupported Content-Type: #{content_type}. Supported types: #{supported}"
    end

    formatter_class.new
  end
end
