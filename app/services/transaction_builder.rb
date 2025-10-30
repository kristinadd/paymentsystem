
class TransactionBuilder
  def initialize(params)
    @params = params
  end

  def build
    params_hash = {
      type: @params[:type],
      merchant_id: @params[:merchant_id],
      amount: @params[:amount],
      status: parse_status(@params[:status]),
      customer_email: @params[:customer_email],
      customer_phone: @params[:customer_phone]
    }

    if @params[:referenced_transaction_id].present?
      referenced_tx = Transaction.find_by(uuid: @params[:referenced_transaction_id])
      params_hash[:referenced_transaction_id] = referenced_tx&.id
    end

    params_hash.compact
  end

  private

  def parse_status(status)
    status.present? ? status.to_s.downcase.to_sym : :approved
  end
end
