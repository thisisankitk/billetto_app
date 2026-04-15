module Voting
  class DownvoteEvent
    include Command::Executable

    attribute :event_id, :string
    attribute :user_id, :string

    validates :event_id, :user_id, presence: true

    def call
      stream = "User$#{user_id}$Event$#{event_id}"
      event = event_store.read
                        .stream(stream)
                        .last
      if event.nil? || event.class == Voting::EventUpvoted
        event_store.publish(
          EventDownvoted.strict(
            data: {
              event_id: event_id,
              user_id: user_id
            }
          ),
          stream_name: stream
        )
      end
    end
  end
end
