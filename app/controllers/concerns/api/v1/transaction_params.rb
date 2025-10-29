module Api
  module V1
    module TransactionParams
      extend ActiveSupport::Concern

      VALID_STATUSES = [ "approved", "reversed", "refunded", "error" ].freeze
      VALID_TYPES = [ "authorize", "charge", "refund", "reversal" ].freeze
      PHONE_REGEX = /\A\d{10,15}\z/  # 10-15 digits only, no special characters

      class ValidationError < StandardError
        attr_reader :errors

        def initialize(errors)
          @errors = errors
          super("Validation failed")
        end
      end

      private

      def permitted_params
        # Require 'data' wrapper
        unless params[:data].present?
          raise ActionController::BadRequest, "Request must include 'data' wrapper"
        end

        params.require(:data).permit(:type, :merchant_id, :referenced_transaction_id, :amount, :status, :customer_email, :customer_phone)
      end

      def transform_params(external_params)
        errors = {}

        validate_type(external_params, errors)
        validate_status(external_params, errors)
        validate_merchant(external_params, errors)
        validate_amount(external_params, errors)
        validate_customer_email(external_params, errors)
        validate_customer_phone(external_params, errors)

        raise ValidationError.new(errors) if errors.any?

        build_internal_params(external_params)
      end

      def validate_type(external_params, errors)
        type = external_params[:type]
        return errors[:type] = "Type is required" if type.blank?
        return if VALID_TYPES.include?(type.to_s.downcase)

        errors[:type] = "Invalid transaction type: #{type}. Must be one of: #{VALID_TYPES.join(", ")}"
      end

      def validate_status(external_params, errors)
        status = external_params[:status]
        return if status.blank?
        return if VALID_STATUSES.include?(status.to_s.downcase)

        errors[:status] = "Invalid status: #{status}. Must be one of: #{VALID_STATUSES.join(", ")}"
      end

      def validate_merchant(external_params, errors)
        merchant_id = external_params[:merchant_id]
        return errors[:merchant_id] = "Merchant ID is required" if merchant_id.blank?

        merchant = Merchant.find_by(id: merchant_id)
        return errors[:merchant_id] = "Merchant not found" if merchant.nil?
        errors[:merchant_id] = "Merchant is not active" unless merchant.active?
      end

      def validate_amount(external_params, errors)
        amount = external_params[:amount]
        return errors[:amount] = "Amount is required" if amount.blank?
        return if amount.to_f > 0

        errors[:amount] = "Amount must be greater than 0"
      end

      def validate_customer_email(external_params, errors)
        customer_email = external_params[:customer_email]
        return errors[:customer_email] = "Customer email is required" if customer_email.blank?
        return if customer_email.match?(URI::MailTo::EMAIL_REGEXP)

        errors[:customer_email] = "Customer email is invalid"
      end

      def validate_customer_phone(external_params, errors)
        customer_phone = external_params[:customer_phone]
        return if customer_phone.blank?
        return if customer_phone.to_s.match?(PHONE_REGEX)

        errors[:customer_phone] = "Customer phone is invalid"
      end

      def build_internal_params(external_params)
        {
          type: external_params[:type],
          merchant_id: external_params[:merchant_id],
          referenced_transaction_id: external_params[:referenced_transaction_id],
          amount: external_params[:amount],
          status: parse_status(external_params[:status]),
          customer_email: external_params[:customer_email],
          customer_phone: external_params[:customer_phone]
        }.compact
      end

      def parse_status(status)
        status.present? ? status.to_s.downcase.to_sym : :approved
      end
    end
  end
end
