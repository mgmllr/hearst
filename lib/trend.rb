require 'redis/set'

class Trend
  def self.add_mention(keyword, timestamp)
    trend_set = Redis::Set.new("trends:keys")
    trend_set << keyword

    set = Redis::Set.new("trends:#{keyword}:timestamps")
    timestamp = Time.parse(timestamp).to_i
    set << timestamp
  end

  def self.get_trend(keyword)
    timestamps = Redis::Set.new("trends:#{keyword}:timestamps")
    timestamps = timestamps.members
    timestamps.map! {|time_str| Time.at(time_str.to_i) }

    {
      :name => keyword,
      :total_mentions => timestamps.count,
      :mentions => timestamps
    }
  end

  def self.all
    trends = []

    redis = Redis.new
    trend_set = redis.keys "trends:*:timestamps"
    trend_set.each do |member|
      keyword = member.split(':')[1]
      trends << get_trend(keyword)
    end

    trends.sort! {|a, b| b[:total_mentions] <=> a[:total_mentions] }

    trends
  end

  def self.score_for_post(object)      
    shares = object[:shares]
    trend = self.get_trend "#{object[:keyword]}" ##Make sure this is the right symbol!!!
    score = calculate_timeliness(object, trend) * shares
    score
  end

  def calculate_timeliness(object, trend)
    if ##twitter
      object_time = Time.parse object["data"]["created_at"]
    if ##instagram
      object_time = Time.at(object["data"]["created_time"])
    trend_start = trend.first
    trend_count = trend[:mentions].count

    mentions = trend[:mentions].sort {|a,b| a < b }

    object_index = trend[:mentions].index(object_time) + 1
    if object_index == 1
      points = 1
    else
      case (tweet_index.to_f / trend_count.to_f)
      when <= 0.1
          points = 0.75
      when > 0.1 && <= 0.25
          points = 0.5
      when > 0.25 && <= 0.5
          points = 0.25
      when > 0.5
          points = 0.1
      end
    end
    points
  end


end
