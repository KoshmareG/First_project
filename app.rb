require 'rubygems'
require 'sinatra'
require 'pony'
require 'sinatra/reloader'
require 'sqlite3'

def form_validation hash
  error = hash.select {|key, value| params[key].empty?}.values.join("; ")
end

def database_init
  return SQLite3::Database.new 'barbershop.db'
end

configure do
  enable :sessions
  db = database_init
  db.execute 'CREATE TABLE IF NOT EXISTS 
      "Users" 
      (
        "Id" INTEGER PRIMARY KEY AUTOINCREMENT,
         "Name" VARCHAR,
        "Phone" VARCHAR,
        "DateStamp" VARCHAR,
        "Barber" VARCHAR
      )'
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Гость'
  end
end

get '/' do
  erb 'Добро пожаловать в наш Barber Shop!'
end

get '/login/form' do
  erb :login_form
end

get '/about' do
  erb :about
end

get '/visit' do
  erb :visit
end

get '/contacts' do
  erb :contacts
end

get '/logout' do
  session.delete(:identity)
  where_user_came_from = session[:previous_url] || '/'
  redirect to where_user_came_from
end

get '/showusers' do
  erb 'Hello'
end

post '/login/attempt' do
  session[:identity] = params['username']
  @username = params[:username]
  @userpassword = params[:userpassword]
  if @username == 'admin' && @userpassword == 'secret'
    erb :showusers
  else
    @error = 'Неверный логин или пароль'
    erb :login_form
  end
end

post '/visit' do
  @user_name = params[:user_name]
  @phone_number = params[:phone_number]
  @date_time = params[:date_time]
  @master = params[:master]

  warning_hash = {  :user_name => 'Введите имя', 
                    :phone_number => 'Введите номер телефона', 
                    :date_time => 'Введите время и дату посещения', 
                    :master => 'Выберите мастера'
                  }
  
  error = form_validation warning_hash

  if error == ''
    file = File.open './public/users.txt', 'a'
      file.puts "Клиент: #{@user_name}   Посещение: #{@date_time}   Мастер: #{@master}   Номер телефона: #{@phone_number}"
    file.close
    db = database_init
    db.execute 'insert into Users (name, phone, datestamp, barber) values (?, ?, ?, ?)', [@user_name, @phone_number, @date_time, @master]
    erb "#{@user_name}, Вы записаны на посещение #{@date_time} #{@master} будет ждать Вас в указанное время!"
  else
    @error = error
    return erb :visit
  end

end

post '/contacts' do
  @name = params[:name]
  @user_email = params[:user_email]
  @user_message = params[:user_message]

  warning_hash = {  :name => 'Введите имя', 
                    :user_email => 'Введите E-Mail', 
                    :user_message => 'Введите сообщение'
                  }
  
  error = form_validation warning_hash

  if error == ''
    file = File.open './public/contacts.txt', 'a'
      file.puts "\n#{@name}\n#{@user_email}\n#{@user_message}"
    file.close
    Pony.mail({
      :to => 'koshmareg@yandex.ru',
      :from => 'koshmareg@gmail.com',
      :subject => 'hi', 
      :body => 'Hello there.',
      :via => :smtp,
      :via_options => {
        :address        => 'smtp.gmail.com',
        :port           => '587',
        :user_name      => 'koshmareg@gmail.com',
        :password       => 'xlsdxkyqmenbttqo',
        :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
        :domain         => "localhost.localdomain" # the HELO domain provided by the client to the server
      }
    })
    erb "Ваше сообщение отправлено"
  else
    @error = error
    return erb :contacts
  end

end
