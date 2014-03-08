require 'rubygems'
require 'data_mapper' # requires all the gems listed above
DataMapper.setup(:default, 'mysql://root:h@localhost/mydb')
#repository(:default).adapter.execute("SET sql_mode = ''")
#removing the above statement throws the error
#DataObjects::SQLError - Field 'login' doesn't have a default value:

class User
  include DataMapper::Resource
  
  property :id,     Serial, :key => true
  property :login, 	String, :required => true, :unique => true, :format => /[a-z]/
  property :email, 	String, :required => true, :unique => true, :format => /@/
  property :password, 	String, :required => true
  property :name, 	String, :required => true
  property :isSeller, Boolean, :default  => false

  property :created_at, DateTime  
  property :updated_at, DateTime  
    
  def self.authenticate(login, pass)
    u = User.first(:login => login )
    return nil if u.nil?
    return u if u.password == pass
  end
end

class Followers
  include DataMapper::Resource
  
  property :id, Serial
  property :user_id,	Integer , :required => true
  property :follower_id, Integer , :required => true
  
  validates_uniqueness_of :user_id, :scope => :follower_id
  
end

class Notif
  include DataMapper::Resource
  
  property :id, Serial
  property :notification, Text,  :lazy => false, :required => true
  property :owner_id, Integer, :required => true
 
  property :created_at, DateTime 
end

class Item
  include DataMapper::Resource
  
  property :item_id, Serial
  property :login, String, :required => true
  property :title, Text, :lazy => false, :required => true
  property :price, Integer, :required => true
  property :path, Integer, :required => true
  property :created_at, DateTime
end      

class PriceDrop
  include DataMapper::Resource

  property :id, Serial
  property :user_id, Integer, :required => true
  property :item_path, Integer, :required => true
  property :item_title, Text, :lazy => false, :required => true
  property :created_at, DateTime

  property :max_price, Integer
  property :orignal_price, Integer

  validates_uniqueness_of :user_id, :scope => :item_path
  #for a given item a User is given only one price drop notification

end

DataMapper.finalize
DataMapper.auto_upgrade!