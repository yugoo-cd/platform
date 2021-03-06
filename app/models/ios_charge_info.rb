# IOS统一充值订单
class IOSChargeInfo

	include Mongoid::Document
	include Mongoid::Timestamps
	# 平台标志
	field :mask
	# 我方订单号
	field :order_id
	# 调用放的订单编号
	field :platform_order_id
	# 状态
	field :state, type: Boolean, default: true
	# 充值金额
	field :money, type: Integer
	# 调用方参数
	field :params
	# 游戏服务器时候处理成功 0 没有，1 成功
	field :add_money, type: Integer, default: 0

	# 充值 充值数据，成功调用方法，失败调用方法
	def self.charge data, suc_func, fail_func, validate_payment=true
		Rails.logger.debug "data = #{data}"
   	return fail_func.call("订单状态失败 #{data}") unless data[:state]
		# 查询订单
		order = JiyuOrder.where(order_id: data['order_id']).first
		# 校验订单
		return fail_func.call "订单不存在 #{data}" unless order
    if validate_payment
		  return fail_func.call "订单中金钱和产品不对应 #{data} order=#{order}" unless order.validate_charge data['money']
    end
		# 查询该订单充值记录
		charge_info = IOSChargeInfo.find_or_create_by(order_id: data['order_id']) do |i|
			data.each{|k,v|i[k] = v}
			i.mask = order.platform_mask
		end
		return suc_func.call "订单已经处理成功" if charge_info.add_money == 1
    Rails.logger.debug "order.product=#{order.product_id}"
		begin
			body = {}
			body['game_user_id'] 	= order.role_id
			body['product_id'] 		= order.product_id
			body['result'] 				= 'SUCCESS'
			body['exorderno'] 		= order.order_id
			body['money'] 				= data['money']
			body['transtime'] 		= Time.now
      Rails.logger.debug "url #{order.ios_url}, body=#{body}"
			resp = HTTParty.post(order.ios_url, body: body).body
      Rails.logger.debug "resp = #{resp}"
		rescue => e
			return fail_func.call "调用服务器失败,resp=#{resp} url=#{order.ios_url}, body = #{body}"
		end
		return fail_func.call "游戏服务器充值失败" unless resp == 'ok'
		charge_info.add_money = 1
		charge_info.save
		suc_func.call
	end


	def self.huawei_charge data, suc_func, fail_func
		Rails.logger.debug "data = #{data}"
   		 return fail_func.call(3) unless data[:state]
		# 查询订单
		order = JiyuOrder.where(order_id: data['order_id']).first
		# 校验订单
		return fail_func.call 3 unless order
		return fail_func.call 3 unless order.validate_charge data['money']
		# 查询该订单充值记录
		charge_info = IOSChargeInfo.find_or_create_by(order_id: data['order_id']) do |i|
			data.each{|k,v|i[k] = v}
			i.mask = order.platform_mask
		end
		return suc_func.call 0 if charge_info.add_money == 1
    	Rails.logger.debug "order.product=#{order.product_id}"
		begin
			body = {}
			body['game_user_id'] 	= order.role_id
			body['product_id'] 		= order.product_id
			body['result'] 				= 'SUCCESS'
			body['exorderno'] 		= order.order_id
			body['money'] 				= data['money']
			body['transtime'] 		= Time.now
      		Rails.logger.debug "url #{order.ios_url}, body=#{body}"
			resp = HTTParty.post(order.ios_url, body: body).body
     		Rails.logger.debug "resp = #{resp}"
		rescue => e
			return fail_func.call 2
		end
		return fail_func.call 94 unless resp == 'ok'
		charge_info.add_money = 1
		charge_info.save
		suc_func.call
	end

end
