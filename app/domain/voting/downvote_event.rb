module Voting
  class DownvoteEvent
    include Command::Executable

    attribute :event_id, :string
    attribute :user_id, :string

    validates :event_id, :user_id, presence: true

    def call
      stream = "User$#{user_id}$Event$#{event_id}"

      event_store.publish(
        EventDownvoted.strict(
          data: {
            event_id: event_id,
            user_id: user_id
          }
        ),
        stream_name: stream,
        expected_version: :none
      )
    end
  end
end