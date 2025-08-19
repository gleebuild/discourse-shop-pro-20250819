
# frozen_string_literal: true
module ShopPro
  class Order < ::ActiveRecord::Base
    self.table_name = "shop_orders"
    has_many :items, class_name: "ShopPro::OrderItem", foreign_key: :order_id, dependent: :destroy

    STATUSES = %w[pending paid shipped cancelled]

    validates :status, inclusion: { in: STATUSES }

    def recalc_total!
      self.total_cents = items.sum(:subtotal_cents)
      save!
    end

    def mark_paid!(ref: nil)
      update!(status: "paid", payment_ref: ref)
    end

    def mark_shipped!
      update!(status: "shipped")
    end

    def mark_cancelled!
      update!(status: "cancelled")
    end
  end
end
