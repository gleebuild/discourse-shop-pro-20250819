
# frozen_string_literal: true
module ShopPro
  class OrderItem < ::ActiveRecord::Base
    self.table_name = "shop_order_items"
    belongs_to :order, class_name: "ShopPro::Order"
    belongs_to :product, class_name: "ShopPro::Product"
    belongs_to :variant, class_name: "ShopPro::Variant", optional: true
  end
end
