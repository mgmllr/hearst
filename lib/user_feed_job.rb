class UserFeedJob
  @queue = :processing

  def self.perform(data)
    ufp = UserFeedProcessor.new(data)
    ufp.process
  end
end
