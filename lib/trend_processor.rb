class TrendProcessor
  def self.process_response(http_response)
    Resque.enqueue(TrendFeedJob, http_response)
  end

  def initialize(http_response)
    json = StringIO.new(http_response)
    parser = Yajl::Parser.new
    @json_hash = parser.parse(json)
  end

  def process_twitter
    @trend_hash = Redis::Set.new('trends')

    tweets = @json_hash["results"]
    tweets.each do |tweet|
      tweet["entities"]["hashtags"].each do |hastag|
        @trends_hash.incr(hastag["text"], 1)
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
