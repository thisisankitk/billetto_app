require "rails_helper"

RSpec.describe Billetto::IngestEvents do
  let(:client) { instance_double(Billetto::Client) }
  let(:service) { described_class.new(url: "/api/v3/public/events?limit=2") }

  before do
    allow(Billetto::Client)
      .to receive(:new).with(url: "/api/v3/public/events?limit=2").and_return(client)
  end

  describe "#call" do
    it "creates events from fetched payload" do
      allow(client).to receive(:fetch_events).and_return(
        events: [
          {
            "id" => "evt-1",
            "title" => "  Spring Festival  ",
            "description" => "  Outdoor music  ",
            "startdate" => "2026-05-10T18:00:00Z",
            "enddate" => "2026-05-10T23:00:00Z",
            "image_link" => "https://example.com/1.png",
            "location" => { "city" => "Copenhagen", "location_name" => "Dock" },
            "minimum_price" => { "amount_in_cents" => 1500, "currency" => "DKK" },
            "organiser" => { "name" => "Billetto Team" },
            "url" => "https://billetto.dk/e/evt-1"
          }
        ],
        next_url: nil,
        has_more: false
      )

      expect { service.call(fetch_all: false) }.to change(Event, :count).by(1)

      event = Event.find_by!(external_id: "evt-1")
      expect(event.title).to eq("Spring Festival")
      expect(event.description).to eq("Outdoor music")
      expect(event.city).to eq("Copenhagen")
      expect(event.venue_name).to eq("Dock")
      expect(event.price_cents).to eq(1500)
      expect(event.currency).to eq("DKK")
      expect(event.organiser_name).to eq("Billetto Team")
      expect(event.url).to eq("https://billetto.dk/e/evt-1")
    end

    it "upserts existing events by external_id" do
      Event.create!(external_id: "evt-2", title: "Old title")

      allow(client).to receive(:fetch_events).and_return(
        events: [
          {
            "id" => "evt-2",
            "title" => "Updated title",
            "description" => "Updated description"
          }
        ],
        next_url: nil,
        has_more: false
      )

      expect { service.call(fetch_all: false) }.not_to change(Event, :count)
      expect(Event.find_by!(external_id: "evt-2").title).to eq("Updated title")
    end

    it "enqueues next page when fetch_all is true and API has more pages" do
      allow(client).to receive(:fetch_events).and_return(
        events: [],
        next_url: "/api/v3/public/events?page=2",
        has_more: true
      )

      configured_job = instance_double(ActiveJob::ConfiguredJob)
      expect(BillettoIngestEventsJob).to receive(:set).with(wait: 2.seconds).and_return(configured_job)
      expect(configured_job)
        .to receive(:perform_later).with(url: "/api/v3/public/events?page=2")

      service.call(fetch_all: true)
    end

    it "does not enqueue next page when fetch_all is false" do
      allow(client).to receive(:fetch_events).and_return(
        events: [],
        next_url: "/api/v3/public/events?page=2",
        has_more: true
      )

      expect(BillettoIngestEventsJob).not_to receive(:set)

      service.call(fetch_all: false)
    end

    it "logs and continues if one event in a batch fails" do
      allow(client).to receive(:fetch_events).and_return(
        events: [
          { "id" => "bad-1", "title" => nil },
          { "id" => "good-1", "title" => "Valid title" }
        ],
        next_url: nil,
        has_more: false
      )
      allow(Rails.logger).to receive(:error)

      expect { service.call(fetch_all: false) }.to change(Event, :count).by(1)
      expect(Event.exists?(external_id: "good-1")).to be(true)
      expect(Rails.logger).to have_received(:error).at_least(:once)
    end
  end
end
