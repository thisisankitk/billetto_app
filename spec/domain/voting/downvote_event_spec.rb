require "rails_helper"

RSpec.describe Voting::DownvoteEvent, type: :model do
  describe "validations" do
    it "requires event_id and user_id" do
      command = described_class.new

      expect(command).not_to be_valid
      expect(command.errors[:event_id]).to include("can't be blank")
      expect(command.errors[:user_id]).to include("can't be blank")
    end
  end

  describe "#call" do
    it "publishes an EventDownvoted fact to a unique user-event stream" do
      event_store = instance_double(RailsEventStore::Client)
      allow(Rails.configuration).to receive(:event_store).and_return(event_store)

      command = described_class.new(event_id: "84", user_id: "user_456")

      expect(event_store).to receive(:publish) do |fact, stream_name:, expected_version:|
        expect(fact).to be_a(Voting::EventDownvoted)
        expect(fact.data).to eq(event_id: "84", user_id: "user_456")
        expect(stream_name).to eq("User$user_456$Event$84")
        expect(expected_version).to eq(:none)
      end

      command.call
    end
  end
end
