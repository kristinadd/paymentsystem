module Api
  module V1
    class TransactionsController < ApplicationController
      include TransactionParams

      skip_before_action :verify_authenticity_token

      rescue_from ActionController::BadRequest, ArgumentError do |e|
        render json: { error: e.message }, status: :bad_request
      end

      rescue_from TransactionParams::ValidationError do |e|
        render json: { errors: e.errors }, status: :bad_request
      end

      def create
        external_params = permitted_params
        internal_params = transform_params(external_params)

        transaction = TransactionFactory.create(
          type: internal_params[:type],
          merchant_id: internal_params[:merchant_id],
          referenced_transaction_id: internal_params[:referenced_transaction_id],
          amount: internal_params[:amount],
          status: internal_params[:status],
          customer_email: internal_params[:customer_email],
          customer_phone: internal_params[:customer_phone]
        )

        render json: {
          data: TransactionSerializer.new(transaction).as_json
        }, status: :created
      end
    end
  end
end
