require "rails_helper"

RSpec.describe Voting::ReadModels::EventVotes, type: :model do
  subject(:handler) { described_class.new }

  let!(:event_record) do
    Event.create!(
      external_id: "ext-100",
      title: "Sample",
      upvotes_count: 0,
      downvotes_count: 0
    )
  end

  describe "#call" do
    it "increments upvotes_count for EventUpvoted" do
      fact = Voting::EventUpvoted.strict(
        data: { event_id: event_record.id.to_s, user_id: "usr-1" }
      )

      expect { handler.call(fact) }
        .to change { event_record.reload.upvotes_count }
        .by(1)
    end

    it "increments downvotes_count for EventDownvoted" do
      fact = Voting::EventDownvoted.strict(
        data: { event_id: event_record.id.to_s, user_id: "usr-1" }
      )

      expect { handler.call(fact) }
        .to change { event_record.reload.downvotes_count }
        .by(1)
    end

    it "ignores unrelated events" do
      unrelated_event_class = Class.new(Fact)
      fact = unrelated_event_class.strict(data: {})

      expect { handler.call(fact) }
        .not_to change { event_record.reload.attributes.slice("upvotes_count", "downvotes_count") }
    end
  end
end
