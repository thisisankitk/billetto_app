module Voting
  module ReadModels
    class EventVotes
      def call(event)
        case event
        when Voting::EventUpvoted
          event = Event.find(event.data[:event_id])
          event.increment!(:upvotes_count)
          event.decrement!(:downvotes_count)
        when Voting::EventDownvoted
          event = Event.find(event.data[:event_id])
          event.increment!(:downvotes_count)
          event.decrement!(:upvotes_count)
        end
      end
    end
  end
end
