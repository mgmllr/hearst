require 'redis'
require 'httparty'

SINGLY_API_BASE = "https://api.singly.com"

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
  if user["twitter"] == "true"
    statuses = HTTParty.get(twitter_url, {:query=> {:access_token=> user["access_token"]}})
  end
  if user["instagram"] == "true"
    photos = HTTParty.get(twitter_url, {:query=> {:access_token=> user["access_token"]}})
  end
end