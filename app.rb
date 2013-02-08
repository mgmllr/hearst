require 'rubygems'
require 'bundler'

Bundler.require


require "sinatra/json"

class ExcellentRussianApp < Sinatra::Application
  helpers Sinatra::JSON

  configure :development do
  end

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

  get '/stylesheet.css' do
    scss :styles
  end
end

