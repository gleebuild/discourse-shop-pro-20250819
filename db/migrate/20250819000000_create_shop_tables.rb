
# frozen_string_literal: true
class CreateShopTables < ActiveRecord::Migration[7.0]
  def up
    unless table_exists?(:shop_products)
      create_table :shop_products do |t|
        t.string  :title, null: false
        t.text    :description
        t.integer :price_cents, null: false, default: 0
        t.string  :currency, null: false, default: (SiteSetting.shop_currency rescue "CNY")
        t.boolean :published, null: false, default: false
        t.string  :main_image_url
        t.text    :gallery_image_urls
        t.integer :topic_id
        t.timestamps
      end
    end

    unless table_exists?(:shop_variants)
      create_table :shop_variants do |t|
        t.references :product, null: false, foreign_key: { to_table: :shop_products }
        t.string  :sku, null: false
        t.integer :price_cents, null: false, default: 0
        t.integer :stock, null: false, default: 0
        t.jsonb   :specs, null: false, default: {}
        t.timestamps
      end
    end
    unless index_exists?(:shop_variants, [:product_id, :sku])
      add_index :shop_variants, [:product_id, :sku], unique: true
    end

    unless table_exists?(:shop_coupons)
      create_table :shop_coupons do |t|
        t.string  :code, null: false
        t.references :product, null: true, foreign_key: { to_table: :shop_products }
        t.integer :discount_cents, null: false, default: 0
        t.integer :usage_limit, null: true
        t.integer :usage_count, null: false, default: 0
        t.boolean :active, null: false, default: true
        t.timestamps
      end
    end
    unless index_exists?(:shop_coupons, :code)
      add_index :shop_coupons, :code, unique: true
    end

    unless table_exists?(:shop_orders)
      create_table :shop_orders do |t|
        t.string  :status, null: false, default: "pending"
        t.string  :currency, null: false, default: (SiteSetting.shop_currency rescue "CNY")
        t.integer :total_cents, null: false, default: 0
        t.string  :customer_name
        t.string  :customer_phone
        t.string  :address
        t.text    :notes
        t.string  :payment_provider
        t.string  :payment_ref
        t.timestamps
      end
    end

    unless table_exists?(:shop_order_items)
      create_table :shop_order_items do |t|
        t.references :order, null: false, foreign_key: { to_table: :shop_orders }
        t.references :product, null: false, foreign_key: { to_table: :shop_products }
        t.references :variant, null: true, foreign_key: { to_table: :shop_variants }
        t.integer :qty, null: false, default: 1
        t.integer :unit_price_cents, null: false, default: 0
        t.integer :subtotal_cents, null: false, default: 0
        t.timestamps
      end
    end
  end

  def down
    drop_table :shop_order_items if table_exists?(:shop_order_items)
    drop_table :shop_orders if table_exists?(:shop_orders)
    drop_table :shop_coupons if table_exists?(:shop_coupons)
    drop_table :shop_variants if table_exists?(:shop_variants)
    drop_table :shop_products if table_exists?(:shop_products)
  end
end
