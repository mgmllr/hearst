class Taskmaster
  def self.process_user_feed_data(response)
    data = response["body"]

    Resque.enqueue(UserFeedJob, data)
  end
end
