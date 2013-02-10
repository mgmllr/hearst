require 'redis/hash_key'

class User
  def self.add_user(profile, access_token)
    user = Redis::HashKey.new("users:#{profile["id"]}")

    user["id"]        = profile["id"]
    user["image"]     = profile["gravatar"] || profile["thumbnail_url"]
    user["twitter"]   = profile["services"].keys.include? "twitter"
    user["instagram"] = profile["services"].keys.include? "instagram"
    user["access_token"] = access_token
  end

  def self.get_user(singly_id)
    Redis::HashKey.new("users:#{singly_id}")
  end

  def self.all
    users = []

    redis = Redis.new
    user_set = redis.keys "users:*"

    user_set.each do |member|
      user = Redis::HashKey.new(member)
      users << {
        :id =>        user["id"],
        :image =>  user["image"],
        :twitter =>   user["twitter"] == "true",
        :instagram => user["instagram"] == "true",
        :access_token => user["access_token"],
      }
    end

    users
  end
end
