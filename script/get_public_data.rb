require 'httparty'

require './lib/model.rb'
Dir.glob('./lib/*.rb') do |model|
  require model
end

TWITTER_API_BASE = "http://search.twitter.com"

def twitter_url
  "#{TWITTER_API_BASE}/search.json"
end

tweets = HTTParty.get(twitter_url, {:query=> {:include_entities=> true, :q=>"\#HearstFashionHack"}})

tp = TrendProcessor.new(tweets.body, :twitter, "hackathon")
tp.process
