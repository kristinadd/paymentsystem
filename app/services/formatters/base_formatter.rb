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
end
