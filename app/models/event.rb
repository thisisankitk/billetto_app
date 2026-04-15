class Event < ApplicationRecord
    include Command::Executable

    VOTE_EVENT_TYPES = [ Voting::EventUpvoted, Voting::EventDownvoted ].freeze

    validates :external_id, presence: true, uniqueness: true
    validates :title, presence: true

    scope :upcoming, -> { where("starts_at >= ?", Date.current) }
    scope :past_event, -> { where("starts_at <= ?", Date.current) }
    scope :recent_first, -> { order(starts_at: :desc) }

    def vote_history_rows
        self.class.vote_history_by_event_ids([ id ]).fetch(id.to_s, [])
    end

    def self.vote_history_by_event_ids(event_ids)
        event_ids_lookup = event_ids.each_with_object({}) do |event_id, lookup|
            lookup[event_id.to_s] = true
        end
        return {} if event_ids_lookup.empty?

        rows_by_event = Hash.new do |events_hash, event_id|
            events_hash[event_id] = Hash.new do |users_hash, user_id|
                users_hash[user_id] = {
                    user_id: user_id,
                    latest_vote: nil,
                    total_votes_by_user: 0
                }
            end
        end

        # We rebuild vote history from Rails Event Store instead of counters because
        # this table needs event-level audit details (user + latest vote + total).
        # Each vote event includes both event_id and user_id in event data and is
        # linked to Event$<event_id>/User$<user_id> streams, so we can aggregate
        # reliably from immutable events.
        Rails.configuration.event_store.read
                 .of_type(VOTE_EVENT_TYPES)
                 .each do |vote_event|
            event_id = vote_event.data.fetch(:event_id).to_s
            next unless event_ids_lookup[event_id]

            user_id = vote_event.data.fetch(:user_id).to_s
            row = rows_by_event[event_id][user_id]
            row[:latest_vote] = vote_label(vote_event)
            row[:total_votes_by_user] += 1
        end

        rows_by_event.transform_values do |rows_by_user|
            rows_by_user.values.sort_by { |row| row[:user_id] }
        end
    end

    def self.vote_label(vote_event)
        vote_event.is_a?(Voting::EventUpvoted) ? "upvote" : "downvote"
    end
    private_class_method :vote_label
end
