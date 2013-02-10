class TrendFeedJob
  @queue = :processing

  def self.perform(data)
    tp = TrendProcessor.new(data)
    tp.process
  end
end

