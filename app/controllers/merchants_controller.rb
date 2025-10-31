class MerchantsController < ApplicationController
  def index
    @merchants = current_user.accessible_merchants
                              .includes(:user)
                              .order(created_at: :desc)
  end
end
