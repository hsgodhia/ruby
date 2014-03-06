require 'json'
require 'sinatra'
require 'sinatra/flash'
require_relative 'db/models'

set :server, 'thin'
set :bind, '0.0.0.0'
set :public_folder, Proc.new { File.join(root, 'public') }
enable :sessions

#----------------------------------
#------server warmup or startup code
$conns_alive = {}
#User.all.each do |u|
 # $conns_alive[u.id.to_i] = []
#end
#----------------------------------------
#the above code gets executed once

get '/itm/:id' do
  @item = Item.first(:path => params[:id])
  @js = ["listing"]
  erb :listing
end

#---------------------------------
#this is the file upload routine
post "/upload" do 

  ff = File.open('counter.txt', "r")
  counter = ff.read.chomp.to_i
  ff.close()
  puts params

  File.open('public/images/' + counter.to_s, "w") do |f|
    f.write(params['myfile'][:tempfile].read)
  end
  counter += 1
  
  ff = File.open('counter.txt', "w")
  ff.write(counter)
  ff.close()

  #create a record for this user
  username = User.first(:id => session[:id]).login
  it = Item.new
  it.attributes = { :login => username, :title => params[:title], :price => params[:price].to_i, :path => (counter-1) }    
  it.save
  session[:success] = "The file was successfully uploaded!"
  redirect '/home'
end

get '/market/showcase' do
  #create a list of images here
  @items = {}
  @prices = {}
  Item.all.each do |itm|
    @items[itm.path] = itm.title
    @prices[itm.path] = itm.price
  end
  puts @items, @prices
  @css = ["market"]
  @js = ["push3"]
  erb :show
end

#------------------------------------
#this is the end for the market, showcase

get '/clear' do
  session.clear
  redirect '/user/login'
end
  
get '/?' do
  @id = session[:id]
  response.headers['Cache-Control'] = 'no-cache, must-revalidate'
  @js = ["es"]
  #here you pass all the js files that will be needed by the template reciever
  erb :reciever
end

get '/home' do
  #deactivate the previous success message of the image upload if any
  if session[:id].nil? then
    redirect '/user/login'
  end
  u = User.first(:id => session[:id])
  if !u.nil? then
    redirect "/#{u.login}"
  else
    erb :login
  end
end

get '/admin/?' do
  @js = ["push3"]
  erb :admin
end

get '/:login' do
  puts $conns_alive[session[:id]]
  @id = session[:id]
  @js = ["push3", "es"]
  @login = params[:login]
  #send to signup if user not found in DB
  redirect '/user/signup/' if User.first(:login => params[:login]).nil?
  u = User.first(:id => session[:id])
  @isSeller = u.isSeller
  @uploadmessage = session[:success] if !session[:success].nil?
  session[:success] = nil

  if @login.eql?(u.login)
    @users = User.all(:id.not => session[:id])
    @owner = true
    #calculate all the latest notifs from my followers and display them here
    following = []
    Followers.all(:user_id => session[:id]).each do |f|
      following << f.follower_id
    end
    @notifs = []
    Notif.all(:owner_id => following, :order => [:created_at.desc], :limit => 6 ).each do |t|  
      @notifs << t.notification
    end
  end
  erb :home
end
#----------------------------------------------------
#User sign-in and sign-up mechansim
get '/user/login/?' do
  #@js = ["login"], with ajax the redirect doesnt work
  u = User.first(:id => session[:id])
  if !session[:id].nil? and !u.nil? then
    redirect "/#{u.login}"
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
    #User.get(:login) did not work out bcoze get is available only for "key fields like id"
    redirect "/#{login}"
  end
end

get '/user/signup/?' do
    erb :signup
end

post '/user/signup/?' do
    u = User.new
    u.attributes = { :login => params[:login], :name => params[:name], :email => params[:email], :password => params[:pwd] , :isSeller => params[:isSeller]}    
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
  
  puts r.user_id
  puts r.follower_id

  if r.save
    "You will now recieve updates from " + User.first(:id => follower_id).login
  else
    "Already following! "
  end
end

#-------------------------------------------------------
#the below manages the SSE notification sending mechanism
def timestamp
  Time.now.strftime("%H:%M:%S")
end

connections = []
notifications = []
	
get '/updates/:id', provides: 'text/event-stream' do
  cache_control :no_cache
  stream :keep_open do |out|
    $conns_alive[params[:id].to_i] = out
    out.callback { $conns_alive[params[:id].to_i] = nil }

    #connections << out
    print "User :", params[:id], " is connected.\n"
   # out.callback { connections.delete(out) }
    
  end
end

#with any post request data is sent, this is by default stored in the hash "params"
post '/push' do
  print "User: ", session[:id], "wants to send a message.\n"
  name = User.first(:id => session[:id]).login
  text = params[:mssg]+", @"+name
  note = Notif.new
  note.attributes = { :notification => text, :owner_id => session[:id] }
  note.save
#when a logged in user click's push, then identify all of his followers and send a message over their channel which is /updates/:id
  notification = params.merge( {'time' => timestamp, 'user' => name } ).to_json
  notifications << notification
  
  #notifications.shift if notifications.length > 10

  #I think there is no use of the variable notifications
  
  #$conns_alive[session[:id]].each { |out| out << "data: #{notification}\n\n" }
  #retrieve all users, for whom I'm a follower_id
  Followers.all(:follower_id => session[:id]).each do |rel|
    print "Sending message of: ", session[:id], " to: ", rel.user_id, "\n"
    $conns_alive[rel.user_id] << "data: #{notification}\n\n" if !$conns_alive[rel.user_id].nil?
  end
  #$conns_alive[session[:id]] << "data: #{notification}\n\n" 
end

post '/missed_data' do
  str = notifications[notifications.length - 1] 
  t = str.index("time")
  temp = str.slice(t+7, 8)

  while notifications.length > 1 and compareDate(temp, params[:last_success]) do
    t = notifications.pop
    $conns_alive[params[:id].to_i] << "data: #{t}\n\n"

    break if notifications.length < 1
  
    str = notifications[notifications.length - 1] 
    t = str.index("time")
    temp = str.slice(t+7, 8)
  end
end

#str represent two dates of the form str1 and str2
def compareDate(str1, str2)
  t1 = str1.split(":")
  t2 = str2.split(":")

  for i in 0..3
    if t1[i].to_i > t2[i].to_i 
      return 1
    end
  end

  return 0
end
    
      


