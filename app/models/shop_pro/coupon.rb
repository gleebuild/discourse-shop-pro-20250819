
# frozen_string_literal: true
module ShopPro
  class Coupon < ::ActiveRecord::Base
    self.table_name = "shop_coupons"
    belongs_to :product, class_name: "ShopPro::Product", optional: true

    validates :code, presence: true, uniqueness: true

    def usable?
      active && (usage_limit.nil? || usage_count < usage_limit)
    end

    def apply_to(amount_cents)
      [0, amount_cents - discount_cents].max
    end
  end
end
