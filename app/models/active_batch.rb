class ActiveBatch
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :desc
  field :name
  #有效期开始时间
  field :begin_time, type: DateTime, default: ->{Time.now}
  #有效期结束时间
  field :end_time, type: DateTime, default: -> {1.year.from_now}
  # 是否可以使用次数,如果没有那么只能使用一次
  field :is_muti, type: Boolean, default: false 
  # 全部平台
  field :all_platform, type: Boolean, default: false
  # 是否给指定平台下的所有服务器使用
  field :all_server, type: Boolean 
  # 指定使用的游戏服务器
  field :zone_ids, type: Array
  # 该激活码能使用次数
  field :lim_times, type: Integer, default: 1

  #所属奖励
  belongs_to :reward
  #持有一个奖励码类型
  belongs_to :active_type, foreign_key: :active_type
  #持有的兑奖码
  has_many :active_codes, dependent: :destroy
  # 所属服务器集合
  field :platform_masks, type: Array 

  # 兼容
  has_and_belongs_to_many :platforms
  
  validates_presence_of :name, message: "必须输入批次名字"

  # 生成指定数量兑换码，生成的兑换码不会重复
  def generate_codes num
    num.times{active_codes.create(times: lim_times)}
  end

  def active_code_size
    ActiveCode.where(active_batch_id: id).size
  end

end
