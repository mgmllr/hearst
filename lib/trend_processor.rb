require 'redis'
require 'redis/hash_key'
require 'resque'

class TrendProcessor
  def self.process_response(http_response, service)
    Resque.enqueue(TrendFeedJob, http_response, service)
  end

  def initialize(http_response, service, trendset)
    json = StringIO.new(http_response)
    parser = Yajl::Parser.new

    @json_hash = parser.parse(json)
    @service = service
    @trendset = trendset
  end

  def process
    case @service
    when :twitter
      process_twitter
    when :instagram
      process_instagram
    end
  end

  def process_twitter
    tweets = @json_hash["results"]
    tweets.each do |tweet|
      tweet["entities"]["hashtags"].each do |hashtag|
        Trend.add_mention(hashtag["text"].downcase, @trendset, tweet["created_at"])
      end
    end
  end

  def process_instagram
    grams = @json_hash["data"]["tags"]
    grams.each do |tag|
      @trends_hash.incr(tag, 1)
    end 
  end
end
