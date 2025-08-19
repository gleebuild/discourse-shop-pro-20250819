
# frozen_string_literal: true
class Admin::ShopPro::BaseController < ::Admin::AdminController
  requires_plugin ::ShopPro::PLUGIN_NAME
  before_action :ensure_admin

  def ensure_admin
    raise Discourse::InvalidAccess.new unless current_user&.admin?
  end
end
