module Voting
  class EventUpvoted < Fact
    SCHEMA = {
      event_id: String,
      user_id: String
    }.freeze

    def stream_names
      [
        "Event$#{data.fetch(:event_id)}",
        "User$#{data.fetch(:user_id)}"
      ]
    end
  end
end