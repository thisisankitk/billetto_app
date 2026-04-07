require "rails_helper"

RSpec.describe ApplicationSubscriptions do
  describe ".handlers" do
    it "includes voting subscriptions by default" do
      handlers = described_class.handlers

      expect(handlers.keys).to include(Voting::EventUpvoted, Voting::EventDownvoted)
    end

    it "merges top-level and domain subscriptions" do
      top_level = { String => [ :noop_handler ] }
      allow(described_class).to receive(:top_level_subscriptions).and_return(top_level)

      handlers = described_class.handlers

      expect(handlers[String]).to eq([ :noop_handler ])
      expect(handlers.keys).to include(Voting::EventUpvoted, Voting::EventDownvoted)
    end
  end
end
