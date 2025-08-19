
# frozen_string_literal: true
class AddOutTradeNoToShopOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :shop_orders, :out_trade_no, :string
    add_index  :shop_orders, :out_trade_no, unique: true
  end
end
