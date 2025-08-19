
# frozen_string_literal: true
class ShopPro::Payments::WechatController < ::ApplicationController
  requires_plugin ::ShopPro::PLUGIN_NAME
  skip_before_action :verify_authenticity_token, only: [:notify]

  def create
    raise Discourse::InvalidAccess.new("WeChat disabled") unless SiteSetting.shop_wechat_enabled

    channel = params[:channel] # "jsapi" | "h5" | "native"
    order = ensure_order!
    out_trade_no = ensure_out_trade_no(order)

    svc = ::ShopPro::WechatV3.new
    desc = "Order ##{order.id}"
    client_ip = request.remote_ip
    openid = params[:openid]

    result = svc.prepay(
      channel: channel,
      out_trade_no: out_trade_no,
      description: desc,
      amount_total: order.total_cents,
      payer_openid: openid,
      client_ip: client_ip
    )

    render_json_dump({ ok: true, order_id: order.id, out_trade_no: out_trade_no, channel: channel }.merge(result))
  rescue => e
    render_json_error e.message
  end

  def notify
    # WeChat v3 notify JSON
    payload = JSON.parse(request.raw_post) rescue {}
    resource = payload["resource"] || {}
    svc = ::ShopPro::WechatV3.new
    data = svc.decrypt_resource(
      ciphertext: resource["ciphertext"],
      nonce: resource["nonce"],
      associated_data: resource["associated_data"]
    )

    out_trade_no = data.dig("out_trade_no")
    transaction_id = data.dig("transaction_id")
    trade_state = data.dig("trade_state")

    if out_trade_no.present? && trade_state == "SUCCESS"
      order = ::ShopPro::Order.find_by(out_trade_no: out_trade_no)
      order&.mark_paid!(ref: transaction_id)
    end

    render json: { code: "SUCCESS", message: "OK" }
  rescue => e
    Rails.logger.error("WeChat notify error: #{e.message}")
    render status: 500, json: { code: "ERROR", message: e.message }
  end

  private

  def ensure_out_trade_no(order)
    return order.out_trade_no if order.out_trade_no.present?
    out_no = "shop#{order.id}-#{Time.now.to_i}"
    order.update!(out_trade_no: out_no, payment_provider: "wechat")
    out_no
  end

  def ensure_order!
    order = nil
    if params[:order_id].present?
      order = ::ShopPro::Order.find(params[:order_id])
    else
      # Create a minimal order from product/qty form if not provided
      product = ::ShopPro::Product.find(params[:product_id])
      qty = params[:qty].to_i; qty = 1 if qty <= 0
      coupon = params[:coupon].presence && ::ShopPro::Coupon.find_by(code: params[:coupon])
      subtotal = product.price_cents * qty
      total = coupon&.usable? ? coupon.apply_to(subtotal) : subtotal
      order = ::ShopPro::Order.create!(
        currency: product.currency,
        total_cents: total,
        customer_name: params[:customer_name],
        customer_phone: params[:customer_phone],
        address: params[:address],
        notes: params[:notes],
        payment_provider: "wechat"
      )
      ::ShopPro::OrderItem.create!(
        order: order, product: product, qty: qty,
        unit_price_cents: product.price_cents, subtotal_cents: subtotal
      )
      order.recalc_total!
    end
    order
  end
end
