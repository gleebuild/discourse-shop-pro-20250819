
# frozen_string_literal: true
class Admin::ShopPro::ProductsController < Admin::ShopPro::BaseController
  def index
    @products = ::ShopPro::Product.order(created_at: :desc).all
    render :index
  end

  def new
    @product = ::ShopPro::Product.new(currency: SiteSetting.shop_currency)
    render :new
  end

  def create
    @product = ::ShopPro::Product.new(product_params)
    if handle_uploads(@product) && @product.save
      bind_topic_custom_field(@product)
      redirect_to admin_shop_pro_products_path, notice: "Created"
    else
      flash.now[:error] = @product.errors.full_messages.join(", ")
      render :new
    end
  end

  def edit
    @product = find_product
    render :edit
  end

  def update
    @product = find_product
    if @product.update(product_params) && handle_uploads(@product)
      bind_topic_custom_field(@product)
      redirect_to admin_shop_pro_products_path, notice: "Updated"
    else
      flash.now[:error] = @product.errors.full_messages.join(", ")
      render :edit
    end
  end

  def destroy
    find_product.destroy!
    redirect_to admin_shop_pro_products_path, notice: "Deleted"
  end

  private

  def find_product
    ::ShopPro::Product.find(params[:id])
  end

  def product_params
    p = params.require(:product).permit(:title, :description, :price_cents, :currency, :published, :topic_id, gallery_image_urls: [])
    p[:gallery_image_urls]&.reject!(&:blank?)
    p
  end

  def handle_uploads(product)
    if params[:product][:main_image].present?
      upload = create_upload(params[:product][:main_image])
      product.main_image_url = upload&.url
    end
    true
  rescue => e
    product.errors.add(:base, "Upload failed: #{e.message}")
    false
  end

  def create_upload(file_param)
    file = file_param.tempfile
    original_filename = file_param.original_filename
    creator = UploadCreator.new(file, original_filename, for_site_setting: false, type: "composer", user_id: current_user.id)
    creator.create_for(current_user.id)
  end

  def bind_topic_custom_field(product)
    if product.topic_id.present?
      if (topic = Topic.find_by(id: product.topic_id))
        topic.custom_fields["shop_product_id"] = product.id
        topic.save_custom_fields(true)
      end
    end
  end
end
