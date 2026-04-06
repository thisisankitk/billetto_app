require "rails_helper"

RSpec.describe Event, type: :model do
  describe "validations" do
    it "requires external_id" do
      event = Event.new(title: "Ruby Meetup")

      expect(event).not_to be_valid
      expect(event.errors[:external_id]).to include("can't be blank")
    end

    it "requires title" do
      event = Event.new(external_id: "evt-1")

      expect(event).not_to be_valid
      expect(event.errors[:title]).to include("can't be blank")
    end

    it "enforces external_id uniqueness" do
      Event.create!(external_id: "evt-1", title: "First")

      duplicate = Event.new(external_id: "evt-1", title: "Second")

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:external_id]).to include("has already been taken")
    end
  end

  describe "scopes" do
    it "returns only upcoming events" do
      old_event = Event.create!(
        external_id: "evt-old",
        title: "Past",
        starts_at: 1.day.ago
      )

      future_event = Event.create!(
        external_id: "evt-new",
        title: "Future",
        starts_at: 2.days.from_now
      )

      expect(Event.upcoming).to include(future_event)
      expect(Event.upcoming).not_to include(old_event)
    end

    it "orders by starts_at descending with recent_first" do
      older = Event.create!(
        external_id: "evt-older",
        title: "Older",
        starts_at: 1.day.from_now
      )
      newer = Event.create!(
        external_id: "evt-newer",
        title: "Newer",
        starts_at: 2.days.from_now
      )

      expect(Event.recent_first.to_a).to eq([ newer, older ])
    end
  end
end