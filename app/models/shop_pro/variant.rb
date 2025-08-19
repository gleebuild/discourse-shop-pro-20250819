
# frozen_string_literal: true
module ShopPro
  class Variant < ::ActiveRecord::Base
    self.table_name = "shop_variants"
    belongs_to :product, class_name: "ShopPro::Product"
    validates :sku, presence: true
    validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
    validates :stock, numericality: { greater_than_or_equal_to: 0 }
  end
end
