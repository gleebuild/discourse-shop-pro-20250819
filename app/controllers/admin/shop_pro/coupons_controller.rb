
# frozen_string_literal: true
class Admin::ShopPro::CouponsController < Admin::ShopPro::BaseController
  def index
    @coupons = ::ShopPro::Coupon.order(created_at: :desc).all
  end

  def new
    @coupon = ::ShopPro::Coupon.new
  end

  def create
    @coupon = ::ShopPro::Coupon.new(coupon_params)
    if @coupon.save
      redirect_to admin_shop_pro_coupons_path, notice: "Created"
    else
      flash.now[:error] = @coupon.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @coupon = find_coupon
  end

  def update
    @coupon = find_coupon
    if @coupon.update(coupon_params)
      redirect_to admin_shop_pro_coupons_path, notice: "Updated"
    else
      flash.now[:error] = @coupon.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    find_coupon.destroy!
    redirect_to admin_shop_pro_coupons_path, notice: "Deleted"
  end

  private
  def find_coupon
    ::ShopPro::Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(:code, :product_id, :discount_cents, :usage_limit, :active)
  end
end
