class MerchantsController < ApplicationController
  def index
    @merchants = current_user.accessible_merchants
                              .order(created_at: :desc)
  end

  def destroy
    merchant = current_user.accessible_merchants.find(params[:id])
    merchant.destroy!

    redirect_to merchants_path, notice: "Merchant '#{merchant.name}' was successfully deleted."
  rescue ActiveRecord::RecordNotFound
    redirect_to merchants_path, alert: "Merchant not found or you don't have permission to delete it."
  rescue ActiveRecord::RecordNotDestroyed => e
    redirect_to merchants_path, alert: "Cannot delete merchant: #{e.message}"
  end
end
