class Formatters::Base
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
    formatted = case errors
    when Hash
      errors
    when ActiveModel::Errors
      errors.messages
    when String
      return { error: errors }
    else
      return { error: errors.to_s }
    end

    # Remap internal field names to API field names for consistency
    formatted = remap_error_fields(formatted)

    { errors: formatted }
  end

  def remap_error_fields(errors)
    return errors unless errors.is_a?(Hash)

    errors.transform_keys do |key|
      case key.to_sym
      when :referenced_transaction
        :referenced_transaction_uuid
      else
        key
      end
    end
  end
end
