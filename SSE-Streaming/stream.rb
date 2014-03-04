require 'json'
require 'sinatra'
require 'sinatra/flash'
require_relative 'db/models'

set :server, 'thin'
set :bind, '0.0.0.0'
set :public_folder, Proc.new { File.join(root, 'public') }
enable :sessions

get '/clear' do
  session.clear
  $current_user = nil
end
  
get '/?' do
  response.headers['Cache-Control'] = 'no-cache, must-revalidate'
  @js = ["es"]
  #here you pass all the js files that will be needed by the template reciever
  erb :reciever
end

get '/home' do
  if session[:id].nil? then
    redirect '/user/login'
  end
  
  u = User.first(:id => session[:id])
  if !$current_user.nil? and !u.nil? and $current_user.eql?(u.login) then
    redirect "/#{$current_user}"
  else
    erb :login
  end
end

get '/admin/?' do
  @js = ["push"]
  erb :admin
end

get "/:login" do
  @login = params[:login]
  if User.first(:login => params[:login]).nil?
    redirect '/user/signup/'
  end
  
  if @login.eql?($current_user)
    @users = User.all(:id.not => session[:id])
    @show = true
    @js = ["push"]
  else
    @js = ["follow"]
  end
  
  erb :home
end

#----------------------------------------------------
#User sign-in and sign-up mechansim
get '/user/login/?' do
  #@js = ["login"], with ajax the redirect doesnt work
  if !session[:id].nil? then
    redirect "/#{$current_user}"
  else
    erb :login
  end
end

post '/user/login/?' do
  login = params[:login]
  pwd = params[:pwd]
  
  if User.authenticate(login, pwd).nil?
    @error = "Username and the password do not match"
    halt erb :login
  else
    session[:id] = User.first(:login => login).id
    $current_user = login
    #User.get(:login) did not work out bcoze get is available only for "key fields like id"
    redirect "/#{login}"
  end
end

get '/user/signup/?' do
    erb :signup
end

post '/user/signup/?' do
    u = User.new
    u.attributes = { :login => params[:login], :name => params[:name], :email => params[:email], :password => params[:pwd] }    
    if u.save
        redirect "/user/login", 301
    else
        @error = u.errors
        halt erb :signup
    end
end

#------------
#handlers for the follow and followers model
post '/follow' do
  user_id = session[:id]
  follower_id = User.first(:login => params[:user_name]).id
  
  r = Followers.new
  r.attributes = { :user_id => user_id, :follower_id => follower_id }
  
  if r.save
    "Successfully saved the relationship!"
  else
    "Failure to save relationship!"
  end
end





#-------------------------------------------------------
#the below manages the SSE notification sending mechanism
def timestamp
  Time.now.strftime("%H:%M:%S")
end

connections = []
notifications = []
	
get '/updates/connect', provides: 'text/event-stream' do
  stream :keep_open do |out|
    connections << out
    out.callback { connections.delete(out) }
  end
end
#with any post request data is sent, this is by default stored in the hash "params"
post '/push' do
  #Add the timestamp to the notification
  puts params
  notification = params.merge( {'time' => timestamp, 'user' => $current_user } ).to_json
  notifications << notification
  puts notification
  notifications.shift if notifications.length > 10
  connections.each { |out| out << "data: #{notification}\n\n" }
end