module ApplicationHelper
  # Convert Rails flash types to Bootstrap alert classes
  def flash_class(type)
    case type.to_sym
    when :notice
      "success"
    when :alert
      "warning"
    when :error
      "danger"
    else
      "info"
    end
  end

  # Get Bootstrap badge class for transaction type
  def transaction_type_badge_class(type)
    case type
    when "AuthorizeTransaction"
      "bg-info"
    when "ChargeTransaction"
      "bg-success"
    when "RefundTransaction"
      "bg-warning"
    when "ReversalTransaction"
      "bg-danger"
    else
      "bg-secondary"
    end
  end

  # Get Bootstrap badge class for transaction status
  def transaction_status_badge_class(status)
    case status
    when "approved"
      "bg-success"
    when "error"
      "bg-danger"
    when "reversed"
      "bg-warning"
    when "refunded"
      "bg-info"
    else
      "bg-secondary"
    end
  end
end
