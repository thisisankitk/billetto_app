module Voting
  class UpvoteEvent
    include Command::Executable

    attribute :event_id, :string
    attribute :user_id, :string

    validates :event_id, :user_id, presence: true

    def call
      stream = "User$#{user_id}$Event$#{event_id}"
      stream_events = event_store.read.stream(stream).to_a
      last_event = stream_events.last

      if last_event.nil? || last_event.is_a?(Voting::EventDownvoted)
        expected_version = stream_events.empty? ? :none : stream_events.size - 1

        event_store.publish(
          EventUpvoted.strict(
            data: {
              event_id: event_id,
              user_id: user_id
            }
          ),
          stream_name: stream,
          expected_version: expected_version
        )
      end
    end
  end
end
