require 'redis/set'

class Trend
  def self.add_mention(keyword, timestamp)
    trend_set = Redis::Set.new("trends:keys")
    trend_set << keyword

    set = Redis::Set.new("trends:#{keyword}:timestamps")
    timestamp = Time.parse(timestamp).to_i
    set << timestamp
  end

  def self.all
    trends = []

    redis = Redis.new
    trend_set = redis.keys "trends:*:timestamps"
    trend_set.each do |member|
      timestamps = Redis::Set.new(member)
      timestamps = timestamps.members
      timestamps.map! {|time_str| Time.at(time_str.to_i) }

      trends << {
        :name => member,
        :total_mentions => timestamps.count,
        :mentions => timestamps
      }
    end

    trends.sort! {|a, b| b[:total_mentions] <=> a[:total_mentions] }

    trends
  end
end
