class BackfillEventVoteHistories < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  VOTE_EVENT_TYPES = [ Voting::EventUpvoted, Voting::EventDownvoted ].freeze

  def up
    return unless table_exists?(:event_vote_histories)

    rows_by_key = Hash.new do |hash, key|
      hash[key] = {
        event_id: key.first,
        user_id: key.last,
        latest_vote: nil,
        total_votes_by_user: 0,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    Rails.configuration.event_store.read.of_type(VOTE_EVENT_TYPES).each do |vote_event|
      event_id = vote_event.data.fetch(:event_id).to_i
      user_id = vote_event.data.fetch(:user_id).to_s
      key = [ event_id, user_id ]

      row = rows_by_key[key]
      row[:latest_vote] = vote_event.is_a?(Voting::EventUpvoted) ? "upvote" : "downvote"
      row[:total_votes_by_user] += 1
      row[:updated_at] = Time.current
    end

    return if rows_by_key.empty?

    existing_event_lookup = Event.where(id: rows_by_key.keys.map(&:first)).pluck(:id).index_with(true)
    upsert_rows = rows_by_key.values.select { |row| existing_event_lookup.key?(row[:event_id]) }
    return if upsert_rows.empty?

    EventVoteHistory.upsert_all(
      upsert_rows,
      unique_by: :index_event_vote_histories_on_event_id_and_user_id
    )
  end

  def down
    # Intentionally no-op: this is a one-way data backfill.
  end
end
