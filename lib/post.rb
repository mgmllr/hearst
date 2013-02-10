require 'redis/hash_key'

class Post
  def self.add_post(user_id, post_data)
    post = Redis::HashKey.new("users:#{user_id}:post:#{post_data[:id]}")
    post.bulk_set(post_data)
  end

  def self.all
    posts = []

    redis = Redis.new
    keys = redis.keys "users:*:post:*"

    keys.each do |key|
      post = Redis::HashKey.new(key)
      posts << post_from_hash_key(post)
    end

    posts
  end

  def self.get_post(user_id, post_id)
    post = Redis::HashKey.new("users:#{user_id}:post:#{post_id}")
    post_from_hash_key(post)
  end

  private

  def self.post_from_hash_key(hash_key)
    {
      :id => hash_key["id"],
      :name => hash_key["name"],
      :post_url => hash_key["post_url"],
      :timestamp => Time.at(hash_key["timestamp"].to_i),
      :amps => hash_key["amps"].to_i,
      :content => hash_key["content"],
      :keywords => hash_key["keywords"].split(','),
      :img_url => hash_key["img_url"]
    }
  end
end
