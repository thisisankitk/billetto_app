require "rails_helper"

RSpec.describe Voting do
  describe ".subscriptions" do
    it "registers read-model handlers for vote events" do
      subscriptions = described_class.subscriptions

      expect(subscriptions.keys).to contain_exactly(
        Voting::EventUpvoted,
        Voting::EventDownvoted
      )

      subscriptions.each_value do |handlers|
        expect(handlers.size).to eq(1)
        expect(handlers.first).to be_a(Voting::ReadModels::EventVotes)
      end
    end
  end
end
