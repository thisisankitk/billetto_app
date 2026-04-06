def handlers
  top_level_subscriptions
    .merge(Voting.subscriptions)
end