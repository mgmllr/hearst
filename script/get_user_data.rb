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

users.each do |user|
  user = redis.hgetall user
  profile = HTTParty.get(singly_profile_url, {:query=> {:access_token=> user["access_token"]}})
  if user["twitter"] == "true"
    statuses = HTTParty.get(twitter_url, {:query=> {:access_token=> user["access_token"]}})
    statuses.each do |status|
      keyword_array = status["data"]["entities"]["hashtags"].map {|ht| ht["text"] })
      keyword_string = keyword_array.join(',')
      Post.add_post(profile.parsed_response["id"], {
          :id => status["data"]["id"],
          :post_url => "http://twitter.com/#{status["user"]["screen_name"]}/status/#{status["data"]["id"]}",
          :timestamp => status["data"]["created_at"],
          :amps => status["data"]["retweet_count"],
          :content => status["data"]["text"],
          :keywords => keyword_string,
          :img_url => status["data"]["media"]["media_url"]
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