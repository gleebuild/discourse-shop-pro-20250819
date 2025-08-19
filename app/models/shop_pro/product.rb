
# frozen_string_literal: true
module ShopPro
  class Product < ::ActiveRecord::Base
    self.table_name = "shop_products"
    has_many :variants, class_name: "ShopPro::Variant", foreign_key: :product_id, dependent: :destroy
    has_many :order_items, class_name: "ShopPro::OrderItem", foreign_key: :product_id

    validates :title, presence: true
    validates :price_cents, numericality: { greater_than_or_equal_to: 0 }

    serialize :gallery_image_urls, Array

    def main_price
      Money.new(price_cents, currency) rescue price_cents
    end
  end
end
