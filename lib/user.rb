require 'redis/hash_key'

class User < Model

  def self.add_user(profile, access_token)
    user = Redis::HashKey.new("users:#{profile["handle"]}", redis)

    user.bulk_set({
      "name" => profile["handle"],
      "image" => profile["gravatar"] || profile["thumbnail_url"],
      "twitter" => profile["services"].keys.include?("twitter"),
      "instagram" => profile["services"].keys.include?("instagram"),
      "access_token" => access_token
    })
  end

  def self.get_user(username)
    user = Redis::HashKey.new("users:#{username}", redis)
    user_from_hash_key(user)
  end

  def self.get_user_score(username)
    user = get_user(username)
    total_score = 0

    post_keys = redis.keys("users:#{username}:post:*")
    post_keys.each do |pk|
      total_score += Trend.score_for_post(Post.get_post(pk.split(":")[1], pk.split(":")[3]))
    end

    total_score
  end

  def self.all
    users = []

    user_set = redis.keys "users:*"
    user_set.map! do |key|
      key_arr = key.split(":")
      "users:#{key_arr[1]}"
    end

    user_set.uniq!

    user_set.each do |member|
      user = Redis::HashKey.new(member, redis)
      users << user_from_hash_key(user)
    end

    users.map! do |user|
      user[:posts] = Post.get_user_posts(user[:name])
      user[:posts].map! do |post|
        post[:score] = Trend.score_for_post(post)
        post
      end
      user[:posts].sort! {|a, b| b[:score] <=> a[:score] }
      user
    end

    users.map! do |user|
      user[:score] = user[:posts].map{|p| p[:score] }.inject{|sum, x| sum + x }
      user
    end

    users.sort! {|a, b| b[:score] <=> a[:score] }

    users
  end

  private

  def self.user_from_hash_key(hash_key)
    {
      :name =>      hash_key["name"],
      :image =>     hash_key["image"],
      :twitter =>   hash_key["twitter"] == "true",
      :instagram => hash_key["instagram"] == "true",
      :access_token => hash_key["access_token"],
    }
  end
end
