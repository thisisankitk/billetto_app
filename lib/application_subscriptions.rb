module ApplicationSubscriptions
  module_function

  def handlers
    top_level_subscriptions
      .merge(Voting.subscriptions)
  end

  def top_level_subscriptions
    {}
  end
end
