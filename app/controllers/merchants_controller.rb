class MerchantsController < ApplicationController
  def index
    @merchants = current_user.accessible_merchants
                              .order(created_at: :desc)
  end

  def edit
    @merchant = current_user.accessible_merchants.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to merchants_path, alert: "Merchant not found or you don't have permission to edit it."
  end

  def update
    @merchant = current_user.accessible_merchants.find(params[:id])

    if @merchant.update(merchant_params)
      redirect_to merchants_path, notice: "Merchant '#{@merchant.name}' was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to merchants_path, alert: "Merchant not found or you don't have permission to update it."
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

  private

  def merchant_params
    params.require(:merchant).permit(:name, :email, :description)
  end
end
