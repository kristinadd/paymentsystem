module Api
  module V1
    class TransactionsController < ApplicationController
      skip_before_action :verify_authenticity_token

      rescue_from ActionController::BadRequest, ArgumentError do |e|
        formatter = Formatters::FormatterFactory.for_request(request)
        render body: formatter.serialize_error(e.message),
               status: :bad_request,
               content_type: formatter.content_type
      end

      rescue_from TransactionValidator::ValidationError do |e|
        formatter = Formatters::FormatterFactory.for_request(request)
        render body: formatter.serialize_error(e.errors),
               status: :bad_request,
               content_type: formatter.content_type
      end

      rescue_from ActiveRecord::RecordInvalid do |e|
        formatter = Formatters::FormatterFactory.for_request(request)
        render body: formatter.serialize_error(e.record.errors),
               status: :unprocessable_entity,
               content_type: formatter.content_type
      end

      def create
        formatter = Formatters::FormatterFactory.for_request(request)
        parsed_data = formatter.parse(request.body.read)
        external_params = extract_params(parsed_data)
        internal_params = transform_params(external_params)

        transaction = TransactionFactory.create(**internal_params)

        render body: formatter.serialize(transaction),
               status: :created,
               content_type: formatter.content_type
      end

      private

      def extract_params(parsed_data)
        unless parsed_data[:data].present?
          raise ActionController::BadRequest, "Request must include 'data' wrapper"
        end

        data = parsed_data[:data]

        ActionController::Parameters.new(data).permit(
          :type, :merchant_id, :referenced_transaction_id, :amount,
          :status, :customer_email, :customer_phone
        )
      end

      def transform_params(external_params)
        validator = TransactionValidator.new(external_params)
        validator.validate!

        builder = TransactionBuilder.new(external_params)
        builder.build
      end
    end
  end
end
