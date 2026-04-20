class EventVoteHistory < ApplicationRecord
  belongs_to :event, inverse_of: :vote_histories

  validates :user_id, presence: true
  validates :latest_vote, inclusion: { in: %w[upvote downvote] }
  validates :total_votes_by_user, numericality: { greater_than_or_equal_to: 0 }
end
