class Event < ApplicationRecord
    has_many :vote_histories,
                     class_name: "EventVoteHistory",
                     dependent: :delete_all,
                     inverse_of: :event

    validates :external_id, presence: true, uniqueness: true
    validates :title, presence: true

    scope :upcoming, -> { where("starts_at >= ?", Time.current) }
    scope :past_event, -> { where("starts_at < ?", Time.current) }
    scope :recent_first, -> { order(starts_at: :desc) }

    def vote_history_rows
        self.class.vote_history_by_event_ids([ id ]).fetch(id.to_s, [])
    end

    def self.vote_history_by_event_ids(event_ids)
        ids = Array(event_ids).compact
        return {} if ids.empty?

        EventVoteHistory
            .where(event_id: ids)
            .order(:user_id)
            .each_with_object(Hash.new { |hash, key| hash[key] = [] }) do |row, memo|
                memo[row.event_id.to_s] << {
                    user_id: row.user_id,
                    latest_vote: row.latest_vote,
                    total_votes_by_user: row.total_votes_by_user
                }
            end
    end
end
