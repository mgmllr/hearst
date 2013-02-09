require 'rubygems'
require 'bundler'

SINGLY_API_BASE = "https://api.singly.com"
HEARST_API_BASE = "http://hearst.api.mashery.com"
TWITTER_API_BASE = "http://search.twitter.com"
INSTAGRAM_API_BASE = "https://api.instagram.com/v1"
REDIS = nil

Bundler.require

require "sinatra/json"

Dir.glob('./lib/*.rb') do |model|
  require model
end

class ExcellentRussianApp < Sinatra::Application
  helpers Sinatra::JSON

  configure :development do
    ENV["REDISCLOUD_URL"] = 'http://localhost:6379'
  end

  configure do
    set :root, File.dirname(__FILE__)

    uri = URI.parse(ENV["REDISCLOUD_URL"])
    REDIS ||= Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

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
    haml :index
  end

  get '/feed.json' do
    feed_output = {
      your_json: 'here'
    }
    json feed_output
  end

  get "/singly" do
    if session[:access_token]
      @profiles = HTTParty.get(profiles_url, {
        :query => {:access_token => session[:access_token]}
        }).parsed_response
      @photos = HTTParty.get(photos_url, {
        :query => {:access_token => session[:access_token]}
        }).parsed_response
    end
    haml :singly
  end

  get "/hearst" do
    @articles = HTTParty.get(articles_url, {:query=> {:keywords=> "fashion", :api_key=>"nvp2n7m2b6stwn3xha8m4ype"}})
    haml :hearst
  end

  get "/twitter" do
    @tweets = HTTParty.get(twitter_url, {:query=> {:include_entities=> true, :q=>"\#HearstFashionHack"}})
    haml :twitter
  end

  get "/instagram" do
    if session[:access_token]
      @grams = HTTParty.get(instagram_url("HearstFashionHack"), {:query=> {:access_token=> session[:access_token]}})
    else
      redirect "/singly"
    end
    haml :instagram
  end

  get '/stylesheet.css' do
    scss :styles
  end

  get "/auth/singly/callback" do
    auth = request.env["omniauth.auth"]
    session[:access_token] = auth.credentials.token
    redirect "/singly"
  end

  get "/logout" do
    session.clear
    redirect "/singly"
  end

  def profiles_url
    "#{SINGLY_API_BASE}/profiles"
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
    "#{INSTAGRAM_API_BASE}/tags/#{tag}/media/recent"
  end
end

