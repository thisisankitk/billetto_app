require "rails_helper"

RSpec.describe Voting::UpvoteEvent, type: :model do
  describe "validations" do
    it "requires event_id and user_id" do
      command = described_class.new

      expect(command).not_to be_valid
      expect(command.errors[:event_id]).to include("can't be blank")
      expect(command.errors[:user_id]).to include("can't be blank")
    end
  end

  describe "#call" do
    it "publishes an EventUpvoted fact to a unique user-event stream" do
      event_store = instance_double(RailsEventStore::Client)
      reader = double("event_store_reader")
      allow(Rails.configuration).to receive(:event_store).and_return(event_store)
      allow(event_store).to receive(:read).and_return(reader)
      allow(reader).to receive(:stream).with("User$user_123$Event$42").and_return(reader)
      allow(reader).to receive(:last).and_return(nil)

      command = described_class.new(event_id: "42", user_id: "user_123")

      expect(event_store).to receive(:publish) do |fact, stream_name:|
        expect(fact).to be_a(Voting::EventUpvoted)
        expect(fact.data).to eq(event_id: "42", user_id: "user_123")
        expect(stream_name).to eq("User$user_123$Event$42")
      end

      command.call
    end
  end
end
