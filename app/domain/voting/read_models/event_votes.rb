module Voting
  module ReadModels
    class EventVotes
      def call(event)
        case event
        when Voting::EventUpvoted
          apply_upvote(event)
        when Voting::EventDownvoted
          apply_downvote(event)
        end
      end

      private

      def apply_upvote(vote_event)
        event_id = vote_event.data.fetch(:event_id)
        user_id = vote_event.data.fetch(:user_id).to_s

        Event.where(id: event_id).update_all(
          upvotes_count: Arel.sql("upvotes_count + 1"),
          downvotes_count: Arel.sql("GREATEST(downvotes_count - 1, 0)"),
          updated_at: Time.current
        )

        upsert_vote_history!(event_id: event_id, user_id: user_id, latest_vote: "upvote")
      end

      def apply_downvote(vote_event)
        event_id = vote_event.data.fetch(:event_id)
        user_id = vote_event.data.fetch(:user_id).to_s

        Event.where(id: event_id).update_all(
          downvotes_count: Arel.sql("downvotes_count + 1"),
          upvotes_count: Arel.sql("GREATEST(upvotes_count - 1, 0)"),
          updated_at: Time.current
        )

        upsert_vote_history!(event_id: event_id, user_id: user_id, latest_vote: "downvote")
      end

      def upsert_vote_history!(event_id:, user_id:, latest_vote:)
        EventVoteHistory.transaction do
          history = EventVoteHistory.lock.find_by(event_id: event_id, user_id: user_id)

          if history
            history.update!(
              latest_vote: latest_vote,
              total_votes_by_user: history.total_votes_by_user + 1
            )
          else
            EventVoteHistory.create!(
              event_id: event_id,
              user_id: user_id,
              latest_vote: latest_vote,
              total_votes_by_user: 1
            )
          end
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end
  end
end
