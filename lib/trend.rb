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

  def self.score_for_post(post)      
    points = 0
    post[:keywords].each do |keyword|
      trend = get_trend("#{post[:keyword]}")
      points += calculate_timeliness(post, trend)
    end
    points * post[:amps]
  end

  def calculate_timeliness(post, trend)
    trend_count = trend[:mentions].count
    mentions = trend[:mentions].sort {|a,b| a <=> b }

    post_index = 0
    mentions.each do |mention|
      post_index += 1 if mention < post[:timestamp]
    end

    if post_index == 0
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
