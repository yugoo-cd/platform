
class MogooController < AppSideController

	def secret_key
		"mogoo-3P60EINppHnQQ2MPCz"
	end

	def success msg=nil
    render json: {error_code: "0", error_message: ""}
  end

  def fail msg=nil
    Rails.logger.error "TtController fail #{msg}"
    render json: {error_code: "1", error_message: msg}
  end

  def login_url
  	"http://test.17mogu.com:8080/mogoo2/gameUser/checkToken.do"
  	# "http://app.17mogu.com:8080/mogoo2/gameUser/checkToken.do"
  end

  def verify_keys
  	%w{uid sid oid gold time}
  end

  def verify token
  	resp = HTTParty.post(login_url, header: {"Cookie" => "JSESSIONID=#{token}"}).body
  	rst = JSON.parse(resp)
  	return [-1, 0] unless rst["res_info"]["response_code"] == "000"
    user = QicUser.find_or_create_by(username: token) do |u|
      u.username = token
      u.password = params[:password]
    end
    [user, token]
  end

	def verify_pay
		md5_be = verify_keys.map{|k|params[k]}.join("-") << "-" << secret_key
    after = Digest::MD5.hexdigest(md5_be).upcase
   # Rails.logger.debug "after = #{after}, sign = #{params[:sign]}"
    return fail("验签错误") unless after == params[:sign]
    payment = HashWithIndifferentAccess.new(
      order_id:           params['eif'],
      platform_order_id:  params['oid'],
      state:              true,
      money:              params['gold'].to_i,
      params:             params.to_json
    )
    IOSChargeInfo.charge payment, proc{|m|success m}, proc{|m|fail m}
	end



end
