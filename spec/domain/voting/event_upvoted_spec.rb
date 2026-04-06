require "rails_helper"

RSpec.describe Voting::EventUpvoted, type: :model do
  describe "#stream_names" do
    it "returns event and user streams" do
      fact = described_class.strict(data: { event_id: "evt_1", user_id: "usr_1" })

      expect(fact.stream_names).to eq([ "Event$evt_1", "User$usr_1" ])
    end
  end
end
