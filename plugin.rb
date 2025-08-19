# frozen_string_literal: true

# name: discourse-shop-pro-20250819
# about: Full-featured (server-rendered) shop for Discourse with products, variants, coupons, and orders
# version: 0.3.0
# authors: GleeBuild + ChatGPT
# url: https://example.com/discourse-shop-pro
# required_version: 3.0.0

enabled_site_setting :shop_enabled

register_asset "stylesheets/common/shop.scss"

after_initialize do
  module ::ShopPro
    PLUGIN_NAME = "discourse-shop-pro-20250819"
  end

  # ---- Topic field support (optional binding to a product) ----
  Topic.register_custom_field_type("shop_product_id", :integer)
  add_to_serializer(:topic_view, :shop_product) do
    pid = object.topic.custom_fields["shop_product_id"]
    if pid && (p = ::ShopPro::Product.find_by(id: pid))
      {
        id: p.id,
        title: p.title,
        price_cents: p.price_cents,
        currency: p.currency,
        published: p.published,
        main_image_url: p.main_image_url
      }
    end
  end

  # ------------------- Routes -------------------
  Discourse::Application.routes.append do
    # Payments
    post "/shop/pay/wechat/:channel" => "shop_pro/payments/wechat#create"
    post "/shop/pay/wechat/notify" => "shop_pro/payments/wechat#notify"
    # Admin (server-rendered) CRUD
    namespace :admin, constraints: AdminConstraint.new do
      namespace :shop_pro do
        resources :products do
          resources :variants, only: [:create, :update, :destroy]
        end
        resources :coupons
        resources :orders do
          member do
            post :mark_paid
            post :mark_shipped
            post :mark_cancelled
          end
        end
        root to: "products#index"
      end
    end

    # Public product page (server-rendered demo)
    get "/shop/products/:id" => "shop_pro/public#show", as: :shop_pro_product
    post "/shop/orders" => "shop_pro/public#create_order", as: :shop_pro_orders
  end
end
