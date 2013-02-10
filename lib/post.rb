require 'redis/hash_key'

class Post
  def self.add_post(user_id, post_data)
    post = Redis::HashKey.new("users:#{user_id}:post:#{post_data[:id]}")
    post.bulk_set(post_data)
  end
end
