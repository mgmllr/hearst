require 'httparty'
require 'yajl'

require './lib/model.rb'
Dir.glob('./lib/*.rb') do |model|
  require model
end

class HearstLoader
  HEARST_API_BASE = "http://hearst.api.mashery.com"

  def self.articles_url
    "#{HEARST_API_BASE}/Article/search"
  end

  def self.clear(trendset)
    redis = Trend.redis

    keys = redis.keys "trends:#{trendset}:*"

    keys.each do |key|
      redis.del key
    end
  end

  def self.load(trendset)
    puts "Booting old data..."
    self.clear(trendset)
    puts "Loading '#{trendset}'..."

    json = StringIO.new(HTTParty.get(articles_url, {:query=> {:keywords=> trendset, :api_key=>"nvp2n7m2b6stwn3xha8m4ype"}}))
    parser = Yajl::Parser.new
    articles = parser.parse(json)
      
    articles["items"].each do |a|
      keywords = a["keywords"].split(', ')
      keywords.each do |kw|
        kw = "nyfw" if kw.downcase == "new york fashion week"
        Trend.add_mention(kw, trendset, a["creation_date"])
        print '.'
      end
    end

    puts
  end
end
