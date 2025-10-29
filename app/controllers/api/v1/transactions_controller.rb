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

      rescue_from ActiveRecord::RecordInvalid do |e|
        render json: { errors: e.record.errors }, status: :unprocessable_entity
      end

      def create
        external_params = permitted_params
        internal_params = transform_params(external_params)

        transaction = TransactionFactory.create(**internal_params)

        render json: {
          data: TransactionSerializer.new(transaction).as_json
        }, status: :created
      end
    end
  end
end
