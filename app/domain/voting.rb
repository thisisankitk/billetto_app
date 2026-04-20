module Voting
  def self.subscriptions
    {
      Voting::EventUpvoted => [ ReadModels::EventVotes.new ],
      Voting::EventDownvoted => [ ReadModels::EventVotes.new, Billetto::SendEventWebhookRequest.new ]
    }
  end
end
