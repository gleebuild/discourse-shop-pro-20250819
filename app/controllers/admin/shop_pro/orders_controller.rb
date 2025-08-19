
# frozen_string_literal: true
class Admin::ShopPro::OrdersController < Admin::ShopPro::BaseController
  def index
    @orders = ::ShopPro::Order.order(created_at: :desc).includes(:items).all
  end

  def show
    @order = find_order
  end

  def mark_paid
    find_order.mark_paid!(ref: "manual-#{Time.now.to_i}")
    redirect_to admin_shop_pro_order_path(params[:id]), notice: "Marked paid"
  end

  def mark_shipped
    find_order.mark_shipped!
    redirect_to admin_shop_pro_order_path(params[:id]), notice: "Marked shipped"
  end

  def mark_cancelled
    find_order.mark_cancelled!
    redirect_to admin_shop_pro_order_path(params[:id]), notice: "Cancelled"
  end

  private

  def find_order
    ::ShopPro::Order.find(params[:id])
  end
end
