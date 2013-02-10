class TrendFeedJob
  @queue = :processing

  def self.perform(data, service)
    tp = TrendProcessor.new(data, service)
    tp.process
  end
end

