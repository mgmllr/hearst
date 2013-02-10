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

uri = URI.parse(ENV["REDISCLOUD_URL"] || "http://localhost:6379")
redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)

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
      timestamp = Time.parse(data["created_at"]).to_i

      Post.add_post(profile.parsed_response["id"], {
        :id => data["id"],
        :name => profile.parsed_response["handle"],
        :post_url => "http://twitter.com/#{data["user"]["screen_name"]}/status/#{data["id"]}",
        :timestamp => timestamp,
        :amps => data["retweet_count"],
        :content => data["text"],
        :keywords => keyword_string,
        :img_url => data["media"] ? data["media"]["media_url"] : nil
      })
      end
  end
  if user["instagram"] == "true"
    grams = HTTParty.get(instagram_url, {:query=> {:access_token=> user["access_token"]}})
    grams.each do |gram|
      data = gram["data"]
      amps = 0
      amps += data["comments"]["count"] if data["comments"]
      amps += data["likes"]["count"] if data["likes"]

      keyword_string = data["tags"].join(',')
      caption = data["caption"]["text"] if data["caption"]

      Post.add_post(profile.parsed_response["id"], {
        :id => data["id"],
        :name => profile.parsed_response["handle"],
        :post_url => data["link"],
        :timestamp => data["created_time"],
        :amps => amps,
        :content => caption,
        :keywords => keyword_string,
        :img_url => data["images"]["standard_resolution"]["url"]
      })
    end
  end
end
