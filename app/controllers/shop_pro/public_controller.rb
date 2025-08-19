
# frozen_string_literal: true
class ShopPro::PublicController < ::ApplicationController
  requires_plugin ::ShopPro::PLUGIN_NAME

  def show
    @product = ::ShopPro::Product.find(params[:id])
  end

  def create_order
    product = ::ShopPro::Product.find(params[:product_id])
    qty = params[:qty].to_i
    qty = 1 if qty <= 0
    coupon = params[:coupon].presence && ::ShopPro::Coupon.find_by(code: params[:coupon])

    subtotal = product.price_cents * qty
    total = coupon&.usable? ? coupon.apply_to(subtotal) : subtotal

    order = ::ShopPro::Order.create!(
      currency: product.currency,
      total_cents: total,
      customer_name: params[:customer_name],
      customer_phone: params[:customer_phone],
      address: params[:address],
      notes: params[:notes]
    )
    ::ShopPro::OrderItem.create!(
      order: order,
      product: product,
      qty: qty,
      unit_price_cents: product.price_cents,
      subtotal_cents: subtotal
    )
    order.recalc_total!

    flash[:notice] = I18n.t("shop_pro.public.order_placed")
    redirect_to shop_pro_product_path(product)
  end
end
