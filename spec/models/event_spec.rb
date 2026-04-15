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

  describe "#vote_history_rows" do
    it "returns latest vote and total votes grouped by user for one event" do
      event_record = Event.create!(
        external_id: "evt-history",
        title: "History",
        starts_at: 1.day.from_now
      )
      other_event = Event.create!(
        external_id: "evt-other",
        title: "Other",
        starts_at: 1.day.from_now
      )

      event_store = Rails.configuration.event_store

      event_store.publish(
        Voting::EventUpvoted.strict(
          data: { event_id: event_record.id.to_s, user_id: "user_1" }
        ),
        stream_name: "Event$#{event_record.id}"
      )
      event_store.publish(
        Voting::EventDownvoted.strict(
          data: { event_id: event_record.id.to_s, user_id: "user_1" }
        ),
        stream_name: "Event$#{event_record.id}"
      )
      event_store.publish(
        Voting::EventUpvoted.strict(
          data: { event_id: event_record.id.to_s, user_id: "user_2" }
        ),
        stream_name: "Event$#{event_record.id}"
      )

      event_store.publish(
        Voting::EventDownvoted.strict(
          data: { event_id: other_event.id.to_s, user_id: "user_1" }
        ),
        stream_name: "Event$#{other_event.id}"
      )

      expect(event_record.vote_history_rows).to eq(
        [
          {
            user_id: "user_1",
            latest_vote: "downvote",
            total_votes_by_user: 2
          },
          {
            user_id: "user_2",
            latest_vote: "upvote",
            total_votes_by_user: 1
          }
        ]
      )
    end
  end

  describe ".vote_history_by_event_ids" do
    it "returns grouped vote history for all requested events" do
      event_one = Event.create!(
        external_id: "evt-history-1",
        title: "History 1",
        starts_at: 1.day.from_now
      )
      event_two = Event.create!(
        external_id: "evt-history-2",
        title: "History 2",
        starts_at: 1.day.from_now
      )
      ignored_event = Event.create!(
        external_id: "evt-history-ignored",
        title: "History ignored",
        starts_at: 1.day.from_now
      )

      event_store = Rails.configuration.event_store

      event_store.publish(
        Voting::EventUpvoted.strict(
          data: { event_id: event_one.id.to_s, user_id: "user_1" }
        ),
        stream_name: "Event$#{event_one.id}"
      )
      event_store.publish(
        Voting::EventDownvoted.strict(
          data: { event_id: event_one.id.to_s, user_id: "user_1" }
        ),
        stream_name: "Event$#{event_one.id}"
      )
      event_store.publish(
        Voting::EventUpvoted.strict(
          data: { event_id: event_two.id.to_s, user_id: "user_2" }
        ),
        stream_name: "Event$#{event_two.id}"
      )
      event_store.publish(
        Voting::EventDownvoted.strict(
          data: { event_id: ignored_event.id.to_s, user_id: "user_9" }
        ),
        stream_name: "Event$#{ignored_event.id}"
      )

      result = Event.vote_history_by_event_ids([ event_one.id, event_two.id ])

      expect(result).to eq(
        {
          event_one.id.to_s => [
            {
              user_id: "user_1",
              latest_vote: "downvote",
              total_votes_by_user: 2
            }
          ],
          event_two.id.to_s => [
            {
              user_id: "user_2",
              latest_vote: "upvote",
              total_votes_by_user: 1
            }
          ]
        }
      )
    end
  end
end
