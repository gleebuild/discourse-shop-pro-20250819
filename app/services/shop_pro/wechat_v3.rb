
# frozen_string_literal: true
require "openssl"
require "base64"
require "securerandom"
require "json"
require "net/http"
require "uri"
require "time"

module ShopPro
  class WechatV3
    API_HOST = "https://api.mch.weixin.qq.com"

    def initialize
      @mchid       = SiteSetting.shop_wechat_mchid
      @appid       = SiteSetting.shop_wechat_appid
      @serial_no   = SiteSetting.shop_wechat_serial_no
      @api_v3_key  = SiteSetting.shop_wechat_api_v3_key
      @private_key = load_private_key(SiteSetting.shop_wechat_private_key_pem)
      @notify_url  = Discourse.base_url + "/shop/pay/wechat/notify"
      raise "WeChat Pay not configured" unless [@mchid, @appid, @serial_no, @api_v3_key].all?(&:present?) && @private_key
    end

    def prepay(channel:, out_trade_no:, description:, amount_total:, payer_openid: nil, client_ip: nil, scene_info: {})
      path = case channel
      when "jsapi"  then "/v3/pay/transactions/jsapi"
      when "h5"     then "/v3/pay/transactions/h5"
      when "native" then "/v3/pay/transactions/native"
      else raise "Unsupported channel"
      end

      body = {
        mchid: @mchid,
        appid: @appid,
        description: description,
        out_trade_no: out_trade_no,
        notify_url: @notify_url,
        amount: { total: amount_total, currency: "CNY" }
      }

      if channel == "jsapi"
        raise "payer_openid required for JSAPI" if payer_openid.blank?
        body[:payer] = { openid: payer_openid }
      end

      if channel == "h5"
        body[:scene_info] = { payer_client_ip: client_ip || "127.0.0.1", h5_info: { type: "Wap" } }
      end

      if channel == "native"
        body[:scene_info] = scene_info if scene_info.present?
      end

      resp = request("POST", path, body.to_json)
      data = JSON.parse(resp.body)

      case channel
      when "jsapi"
        prepay_id = data["prepay_id"]
        raise "prepay_id missing: #{resp.body}" if prepay_id.blank?
        js_params = build_jsapi_params(prepay_id)
        { prepay_id: prepay_id, js_params: js_params, raw: data }
      when "h5"
        { h5_url: data["h5_url"], raw: data }
      when "native"
        { code_url: data["code_url"], raw: data }
      end
    end

    # Build params for WeixinJSBridge.invoke('getBrandWCPayRequest', ...)
    def build_jsapi_params(prepay_id)
      ts = Time.now.to_i.to_s
      nonce = SecureRandom.hex(16)
      pkg = "prepay_id=#{prepay_id}"
      sign_str = [@appid, ts, nonce, pkg].join("\n") + "\n"
      signature = Base64.strict_encode64(@private_key.sign("SHA256", sign_str))
      {
        appId: @appid,
        timeStamp: ts,
        nonceStr: nonce,
        package: pkg,
        signType: "RSA",
        paySign: signature
      }
    end

    # Decrypt notification resource using API v3 key (AES-256-GCM)
    def decrypt_resource(ciphertext:, nonce:, associated_data:)
      key = @api_v3_key
      cipher = OpenSSL::Cipher.new("aes-256-gcm")
      cipher.decrypt
      cipher.key = key
      cipher.iv = nonce
      cipher.auth_data = associated_data
      data = Base64.decode64(ciphertext)
      tag = data[-16..-1]
      cipher.auth_tag = tag
      decrypted = cipher.update(data[0...-16]) + cipher.final
      JSON.parse(decrypted)
    end

    private

    def load_private_key(pem)
      return nil if pem.blank?
      OpenSSL::PKey::RSA.new(pem)
    rescue => e
      Rails.logger.error("WechatV3 private key error: #{e.message}")
      nil
    end

    def request(method, path, body_json)
      ts = Time.now.to_i.to_s
      nonce = SecureRandom.hex(16)
      signature = sign_request(method, path, ts, nonce, body_json || "")
      auth = %(WECHATPAY2-SHA256-RSA2048 mchid="#{@mchid}",nonce_str="#{nonce}",timestamp="#{ts}",serial_no="#{@serial_no}",signature="#{signature}")
      uri = URI(API_HOST + path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      req = case method
        when "POST" then Net::HTTP::Post.new(uri)
        when "GET"  then Net::HTTP::Get.new(uri)
      end
      req["Content-Type"] = "application/json"
      req["Accept"] = "application/json"
      req["Authorization"] = auth
      req.body = body_json if body_json.present?
      res = http.request(req)
      unless res.code.to_i.between?(200, 299)
        raise "WeChat API error: #{res.code} #{res.body}"
      end
      res
    end

    def sign_request(method, path, ts, nonce, body)
      str = [method, path, ts, nonce, body].join("\n") + "\n"
      sig = @private_key.sign("SHA256", str)
      Base64.strict_encode64(sig)
    end
  end
end
