
# frozen_string_literal: true
class Admin::ShopPro::VariantsController < Admin::ShopPro::BaseController
  before_action :load_product

  def create
    v = @product.variants.build(variant_params)
    if v.save
      redirect_to edit_admin_shop_pro_product_path(@product), notice: "Variant created"
    else
      redirect_to edit_admin_shop_pro_product_path(@product), alert: v.errors.full_messages.join(", ")
    end
  end

  def update
    v = @product.variants.find(params[:id])
    if v.update(variant_params)
      redirect_to edit_admin_shop_pro_product_path(@product), notice: "Variant updated"
    else
      redirect_to edit_admin_shop_pro_product_path(@product), alert: v.errors.full_messages.join(", ")
    end
  end

  def destroy
    v = @product.variants.find(params[:id])
    v.destroy!
    redirect_to edit_admin_shop_pro_product_path(@product), notice: "Variant deleted"
  end

  private
  def load_product
    @product = ::ShopPro::Product.find(params[:product_id])
  end

  def variant_params
    params.require(:variant).permit(:sku, :price_cents, :stock)
  end
end
