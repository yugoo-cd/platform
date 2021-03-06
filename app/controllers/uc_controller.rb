class UcController < AppSideController

  def success msg=nil
    logger.debug msg if msg
    render text: "success"
  end

  def fail msg=nil
    logger.error msg if msg
    render text: "fail"
  end

  def key order_id
    mask = JiyuOrder.find_by(order_id: order_id).platform_mask
    Rails.logger.debug "mask===#{mask}"
    case mask.to_s
    when /XICHU-UC/
      "39889cf08f1901acd5fc386a4773f2f3"
    when /XICHU-YAOJI-UC/
      "d32be774745c20fc0eff882af1b41d42"
    when /ANDROID-XICHU-ZHANSHEN-UC/
      "cc0c51ccf5741d529d15291599a9f1e6"
    else
      "39889cf08f1901acd5fc386a4773f2f3"
    end
  end

  def uc_verify_sign
    #params['data'].gsub!("=>",":")
    logger.debug params['data']
    hash_data = if params['data'].is_a?(String) then JSON.parse(params['data']) else params['data'].to_h end
   # hash_data = JSON.parse params['data']
    sign = params['sign']
    md5_before = hash_data.to_a.sort{|a,b|a[0]<=>b[0]}.map{|a|a.join("=")}.join("")
    #private_key = "a6fb07456626474f9ed441b455dc9922"
    #private_key = "39889cf08f1901acd5fc386a4773f2f3"
    private_key = key(hash_data['callbackInfo'])
    logger.debug "md5_before=#{md5_before}"
    Rails.logger.debug "private_key===#{private_key}"
    md5 = Digest::MD5.hexdigest(md5_before.to_s+private_key.to_s)
    return fail "md5验证错误 params= #{params}" unless sign == md5

    payment = HashWithIndifferentAccess.new(
      order_id: hash_data['callbackInfo'],
      platform_order_id: hash_data['orderId'],
      state: hash_data['orderStatus'] == 'S',
      money: hash_data['amount'].to_i,
      params: hash_data
    )
    IOSChargeInfo.charge payment, proc{|m|success m}, proc{|m|fail m}
  end

end
