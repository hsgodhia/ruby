require 'rubygems'
require 'data_mapper' # requires all the gems listed above
DataMapper.setup(:default, 'mysql://root:h@localhost/mydb')
#repository(:default).adapter.execute("SET sql_mode = ''")
#removing the above statement throws the error
#DataObjects::SQLError - Field 'login' doesn't have a default value:

class User
  include DataMapper::Resource
  
  property :id,         	Serial, :key => true
  property :login, 	String, :required => true, :unique => true, :format => /[a-z]/
  property :email, 	String, :required => true, :unique => true, :format => /@/
  property :password, 	String, :required => true
  property :name, 	String, :length => (2..10)
  
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
  property :user_id,	Integer, :unique_index => true
  property :follower_id, Integer, :unique_index => true
  
  validates_uniqueness_of :user_id, :scope => :follower_id
  
end

DataMapper.finalize
DataMapper.auto_upgrade!