class TrendProcessor
  def self.process_response(http_response)
    Resque.enqueue(TrendFeedJob, http_response)
  end

  def initialize(http_response)
    json = StringIO.new(http_response)
    parser = Yajl::Parser.new
    @json_hash = parser.parse(json)
  end

  def process
    
  end
end
