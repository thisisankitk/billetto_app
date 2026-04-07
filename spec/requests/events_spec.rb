require "rails_helper"

RSpec.describe "Events", type: :request do
  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
  end

  describe "GET /" do
    it "returns success and lists events in recent-first order" do
      older = Event.create!(
        external_id: "evt-older",
        title: "Older Event",
        description: "Older description",
        starts_at: 1.day.from_now
      )
      newer = Event.create!(
        external_id: "evt-newer",
        title: "Newer Event",
        description: "Newer description",
        starts_at: 3.days.from_now
      )

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(older.title)
      expect(response.body).to include(newer.title)
      expect(response.body.index(newer.title)).to be < response.body.index(older.title)
    end

    it "paginates events with 20 records per page" do
      21.times do |idx|
        Event.create!(
          external_id: "evt-page-#{idx}",
          title: "Event #{idx}",
          starts_at: idx.hours.from_now
        )
      end

      get root_path

      expect(response.body).to include("Event 20")
      expect(response.body).not_to include("Event 0")
      expect(response.body).to include("Next")

      get root_path(page: 2)

      expect(response.body).to include("Event 0")
      expect(response.body).to include("Previous")
    end

    it "includes a brief description in event cards" do
      Event.create!(
        external_id: "evt-desc",
        title: "Event with description",
        description: "A short summary",
        starts_at: 2.days.from_now
      )

      get root_path

      expect(response.body).to include("A short summary")
    end
  end
end
