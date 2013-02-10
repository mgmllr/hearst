require 'rubygems'
require 'bundler'

SINGLY_API_BASE = "https://api.singly.com"
HEARST_API_BASE = "http://hearst.api.mashery.com"
TWITTER_API_BASE = "http://search.twitter.com"
INSTAGRAM_API_BASE = "https://api.instagram.com/v1"

Bundler.require

require "sinatra/json"
require "redis/hash_key"

require './lib/model.rb'

Dir.glob('./lib/*.rb') do |model|
  require model
end

class ExcellentRussianApp < Sinatra::Application
  helpers Sinatra::JSON

  configure do
    set :root, File.dirname(__FILE__)

    Compass.configuration do |config|
      config.project_path = File.dirname(__FILE__)
      config.sass_dir = 'views'
    end

    set :haml, { :format => :html5 }
    set :sass, Compass.sass_engine_options
    set :scss, Compass.sass_engine_options
    set :public_folder, 'public'
    set :sessions, true
  end

  use OmniAuth::Builder do
    provider :singly, '21ff03d9e1e42e28c5c53e94c8c36208', '942d969f6a6963afb85a7aa68b21bedd'
  end

  helpers do 
    def auth_path(service)
      url = "/auth/singly?service=#{service}"
      url += "&access_token#{session[:access_token]}" if session[:access_token]
      url
    end
  end

  get '/' do
    get_user_data
    @trends = Trend.all
    json = StringIO.new(HTTParty.get(articles_url, {:query=> {:keywords=> "fashion", :api_key=>"nvp2n7m2b6stwn3xha8m4ype"}}))
    parser = Yajl::Parser.new
    @articles = parser.parse(json)
    haml :index
  end

  get '/feed.json' do
    feed_output = {
      your_json: 'here'
    }
    json feed_output
  end

  get "/singly" do
    get_user_data
    haml :singly
  end

  get "/clear_redis" do
    r = Redis.new
    r.keys.each {|key| r.del key }
    redirect "/"
  end

  def get_user_data
    if session[:access_token]
      @profiles = HTTParty.get(profiles_url, {
        :query => {:access_token => session[:access_token]}
      }).parsed_response

      User.add_user(@profiles, session[:access_token])
      session[:current_user] = @profiles["handle"]

      @photos = HTTParty.get(photos_url, {
        :query => {:access_token => session[:access_token]}
        }).parsed_response
    end
  end

  get "/hearst" do
    json = StringIO.new(HTTParty.get(articles_url, {:query=> {:keywords=> "fashion", :api_key=>"nvp2n7m2b6stwn3xha8m4ype"}}))
    parser = Yajl::Parser.new
    @articles = parser.parse(json)

    haml :hearst
  end

  get "/twitter" do
    @tweets = HTTParty.get(twitter_url, {:query=> {:include_entities=> true, :q=>"\#HearstFashionHack"}})
    puts @tweets.first.inspect
    haml :twitter
  end

  get "/instagram" do
    if session[:access_token]
      params = {:query=> {:access_token=> session[:access_token]}}.inspect
      puts params.inspect
      @tag = "HearstFashionHack"
      # puts instagram_url(@tag)
      @grams = HTTParty.get(instagram_url(@tag), {:query=> {:access_token=> session[:access_token]}})
      puts @grams.inspect
    else
      redirect "/singly"
    end
    haml :instagram
  end

  get "/stylesheet.css" do
    scss :styles
  end

  get "/auth/singly/callback" do
    auth = request.env["omniauth.auth"]
    puts auth.inspect
    session[:access_token] = auth.credentials.token
    redirect "/"
  end

  get "/about" do
    haml :about
  end

  get "/logout" do
    session.clear
    redirect "/"
  end

  def profiles_url
    "#{SINGLY_API_BASE}/profile"
  end

  def photos_url
    "#{SINGLY_API_BASE}/types/photos"
  end

  def articles_url
    "#{HEARST_API_BASE}/Article/search"
  end

  def twitter_url
    "#{TWITTER_API_BASE}/search.json"
  end

  def instagram_url(tag)
    "#{SINGLY_API_BASE}/proxy/instagram/tags/#{tag}/media/recent"
  end

  def current_user
    User.get_user(session[:current_user])
  end

  def logged_in?
    !session[:current_user].nil?
  end

  def partial(haml_file)
    haml haml_file, :layout => false
  end
end

