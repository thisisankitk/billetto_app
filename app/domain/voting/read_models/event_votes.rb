module Voting
  module ReadModels
    class EventVotes
      def call(event)
        case event
        when Voting::EventUpvoted
          Event.find(event.data[:event_id]).increment!(:upvotes_count)
        when Voting::EventDownvoted
          Event.find(event.data[:event_id]).increment!(:downvotes_count)
        end
      end
    end
  end
end