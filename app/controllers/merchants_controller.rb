class MerchantsController < ApplicationController
  before_action :set_merchant, only: [ :edit, :update, :destroy ]

  def index
    @merchants = current_user.accessible_merchants
                              .order(created_at: :desc)
  end

  def edit; end

  def update
    if @merchant.update(merchant_params)
      redirect_to merchants_path, notice: "Merchant '#{@merchant.name}' was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    merchant_name = @merchant.name
    @merchant.destroy!

    redirect_to merchants_path, notice: "Merchant '#{merchant_name}' was successfully deleted."
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to merchants_path, alert: "Cannot delete merchant: #{e.message}"
  end

  private

  def set_merchant
    @merchant = current_user.accessible_merchants.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to merchants_path, alert: "Merchant not found or you don't have permission to access it."
  end

  def merchant_params
    params.require(:merchant).permit(:name, :email, :description)
  end
end
