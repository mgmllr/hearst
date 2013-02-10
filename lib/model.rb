class Model
  def self.redis
    uri = URI.parse(ENV["REDISCLOUD_URL"] || "http://localhost:6379")
  
    puts "*******************************"
    puts "initializing redis client"
    puts uri

    @redis ||= Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
  end
end
