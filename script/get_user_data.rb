require 'redis'
require 'httparty'

SINGLY_API_BASE = "https://api.singly.com"

def singly_profile_url
  "#{SINGLY_API_BASE}/profile"
end

def twitter_url
  "#{SINGLY_API_BASE}/types/statuses"
end

def instagram_url
  "#{SINGLY_API_BASE}/types/photos"
end

redis = Redis.new

users = redis.keys "users:*"

Dir.glob('./lib/*.rb') do |model|
  require model
end

users.each do |user|
  user = redis.hgetall user
  profile = HTTParty.get(singly_profile_url, {:query=> {:access_token=> user["access_token"]}})
  if user["twitter"] == "true"
    statuses = HTTParty.get(twitter_url, {:query=> {:access_token=> user["access_token"]}})
    statuses.each do |status|
      data = status["data"]
      keyword_array = data["entities"]["hashtags"].map {|ht| ht["text"] }
      keyword_string = keyword_array.join(',')
      Post.add_post(profile.parsed_response["id"], {
          :id => data["id"],
          :post_url => "http://twitter.com/#{data["user"]["screen_name"]}/status/#{data["id"]}",
          :timestamp => data["created_at"],
          :amps => data["retweet_count"],
          :content => data["text"],
          :keywords => keyword_string,
          :img_url => data["media"] ? data["media"]["media_url"] : nil
      })
      end
  end
  if user["instagram"] == "true"
    grams = HTTParty.get(twitter_url, {:query=> {:access_token=> user["access_token"]}})
    grams.each do |gram|
      amps = gram["comments"]["count"] + gram["likes"]["count"]
      keyword_string = status["data"]["tags"].join(',')
      Post.add_post(profile.parsed_response["id"], {
          :id => gram["id"],
          :post_url => gram["link"],
          :timestamp => gram["created_time"],
          :amps => amps,
          :content => gram["caption"]["text"],
          :keywords => keyword_string,
          :img_url => gram["images"]["standard_resolution"]["url"]
      })
    end
  end
end