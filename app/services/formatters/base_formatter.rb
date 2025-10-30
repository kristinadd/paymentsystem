class Formatters::BaseFormatter
  def parse(request_body)
    raise NotImplementedError, "#{self.class} must implement #parse"
  end

  def serialize(transaction)
    raise NotImplementedError, "#{self.class} must implement #serialize"
  end

  def serialize_error(errors)
    raise NotImplementedError, "#{self.class} must implement #serialize_error"
  end

  def content_type
    raise NotImplementedError, "#{self.class} must implement #content_type"
  end

  protected

  def transaction_to_hash(transaction)
    TransactionSerializer.new(transaction).as_json
  end

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
