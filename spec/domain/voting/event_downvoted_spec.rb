require "rails_helper"

RSpec.describe Voting::EventDownvoted, type: :model do
  describe "#stream_names" do
    it "returns event and user streams" do
      fact = described_class.strict(data: { event_id: "evt_2", user_id: "usr_2" })

      expect(fact.stream_names).to eq([ "Event$evt_2", "User$usr_2" ])
    end
  end
end
