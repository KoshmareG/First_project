require 'rubygems'
require 'sinatra'
require 'pony'
require 'sinatra/reloader'
require 'sqlite3'

def form_validation hash
  error = hash.select {|key, value| params[key].empty?}.values.join("; ")
end

def database_init
  @db = SQLite3::Database.new 'barbershop.db'
  @db.results_as_hash = true
  return @db
end

def barbers_table
  database_init
  @barbers_table = @db.execute 'select * from barbers'
  @db.close
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
  db.execute 'CREATE TABLE IF NOT EXISTS 
      "Barbers" 
      (
        "Id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "Barber" VARCHAR UNIQUE
      )'
  barbers = ['Матвей', 'Георгий', 'Святослав']
  barbers.each do |new_barber|
    db.execute 'insert or ignore into Barbers (Barber) values (?)', new_barber
  end
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
  barbers_table
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
  database_init
  @user_table = @db.execute 'select * from users'
  @db.close
  erb :showusers
end

post '/login/attempt' do
  session[:identity] = params['username']
  @username = params[:username]
  @userpassword = params[:userpassword]
  if @username == 'admin' && @userpassword == 'secret'
    redirect '/showusers'
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
    barbers_table
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
    erb "Ваше сообщение отправлено"
  else
    @error = error
    return erb :contacts
  end

end
