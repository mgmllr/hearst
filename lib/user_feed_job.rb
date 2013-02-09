class UserFeedJob
  @queue = :processing

  def self.perform(data)
    # data = response.body from Taskmaster class
  end
end
