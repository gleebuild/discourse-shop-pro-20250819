
# discourse-shop-pro-20250819

A pragmatic, server-rendered Discourse shop plugin that avoids common Ember/packaging pitfalls. 
It provides **Products**, **Variants**, **Coupons**, and **Orders** with a minimal public product page.

> Built 2025-08-19 02:31:35

## Why server-rendered admin?
Recent Discourse builds use Embroider/Octane in Admin. To avoid frequent front-end breakages and build-memory issues, 
this plugin renders Admin CRUD with plain Rails views under `/admin/shop_pro/*`. It compiles quickly and has far fewer moving parts.

## Features
- Products with price, currency, main image upload (uses Discourse Uploads), gallery URLs, published flag
- Variants (sku/price/stock)
- Coupons (code/discount/limit/active) + basic application on public order form
- Orders with status workflow (pending → paid → shipped / cancelled)
- Optional binding of a Product to a Topic via `topic_id`; the Topic serializer exposes `topic_view.shop_product`
- Public product page at `/shop/products/:id` with simple "place order" demo (no payment gateway yet)

## Install
1. SSH to your Discourse host (the **host**, not inside the container):
   ```bash
   cd /var/discourse
   ./launcher enter app
   # Inside the container:
   cd /var/www/discourse/plugins
   # Upload and unzip the plugin ZIP here as `discourse-shop-pro-20250819`
   ```
   The folder name **must** exactly match `discourse-shop-pro-20250819` (avoids the common "Plugin name vs directory" error).

2. Rebuild or restart:
   ```bash
   exit  # leave container if you used enter
   ./launcher rebuild app
   # or inside the container:
   # sv restart unicorn
   ```

3. In Discourse Admin → Settings, enable **shop_enabled**.

## Usage
- Admin → go to `/admin/shop_pro/products` for CRUD (also `/admin/shop_pro/coupons`, `/admin/shop_pro/orders`).
- Public product page: `/shop/products/:id` (demo order flow).

## Known Good Practices (avoid your past issues)
- **Folder name matches plugin.rb name**: `discourse-shop-pro-20250819`
- **No Ember admin** to sidestep Embroider and Node memory problems during assets:precompile
- **Rails 7 migration syntax** compatible with modern Discourse (Rails 7/8 forward)
- Uploads via `UploadCreator` with current_user context (prevents `nil user` errors)
- Admin controllers inherit from `Admin::AdminController` and apply `AdminConstraint` routes (staff-only)
- Topic binding performed safely; missing topic is ignored (no crash)

## Extending to Payments
Stubs for WeChat/Alipay are exposed via site settings. Implement your gateway controllers under `app/controllers/shop_pro/payments/*` 
and change the public order form to create payment intents and webhook handlers. Then call `order.mark_paid!` upon confirmation.

## Uninstall
Remove the plugin folder and rebuild:
```bash
rm -rf /var/www/discourse/plugins/discourse-shop-pro-20250819
cd /var/discourse && ./launcher rebuild app
```

## License
MIT

## WeChat Pay v3
- Endpoints: POST /shop/pay/wechat/:channel (jsapi|h5|native), POST /shop/pay/wechat/notify
- Configure site settings (mchid, appid, serial_no, api_v3_key, private key PEM)
- JSAPI requires openid; H5 returns h5_url; Native returns code_url.
