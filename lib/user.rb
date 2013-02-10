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
    user = Redis::HashKey.new("users:#{singly_id}")
    user_from_hash_key(user)
  end

  def self.all
    users = []

    redis = Redis.new
    user_set = redis.keys "users:*"

    user_set.each do |member|
      user = Redis::HashKey.new(member)
      users << user_from_hash_key(user)
    end

    users
  end

  private

  def self.user_from_hash_key(hash_key)
    {
      :id =>        hash_key["id"],
      :image =>     hash_key["image"],
      :twitter =>   hash_key["twitter"] == "true",
      :instagram => hash_key["instagram"] == "true",
      :access_token => hash_key["access_token"],
    }
  end

end
