
# frozen_string_literal: true
class AddOutTradeNoToShopOrders < ActiveRecord::Migration[7.0]
  def up
    unless column_exists?(:shop_orders, :out_trade_no)
      add_column :shop_orders, :out_trade_no, :string
    end
    unless index_exists?(:shop_orders, :out_trade_no)
      add_index  :shop_orders, :out_trade_no, unique: true
    end
  end

  def down
    if index_exists?(:shop_orders, :out_trade_no)
      remove_index :shop_orders, :out_trade_no
    end
    if column_exists?(:shop_orders, :out_trade_no)
      remove_column :shop_orders, :out_trade_no
    end
  end
end
