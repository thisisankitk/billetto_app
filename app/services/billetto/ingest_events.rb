module Billetto
  class IngestEvents
    def initialize(url: nil)
      @client = Billetto::Client.new(url: url)
    end

    def call(fetch_all: false)
      response = client.fetch_events

      ingest_batch(response[:events])

      enqueue_next_page(response[:next_url]) if response[:has_more] && fetch_all
    end

    private

    attr_reader :client

    def ingest_batch(events)
      events.each do |data|
        upsert_event(data)
      rescue => e
        Rails.logger.error(
          "[Billetto::IngestEvents] Failed event #{data['id']}: #{e.message}"
        )
      end
    end

    def upsert_event(data)
      event = Event.find_or_initialize_by(external_id: data["id"])

      event.assign_attributes(
        title: clean(data["title"]),
        description: clean(data["description"]),
        starts_at: parse_time(data["startdate"]),
        ends_at: parse_time(data["enddate"]),
        image_url: data["image_link"],
        city: data.dig("location", "city"),
        venue_name: data.dig("location", "location_name"),
        price_cents: data.dig("minimum_price", "amount_in_cents"),
        currency: data.dig("minimum_price", "currency"),
        organiser_name: data.dig("organiser", "name"),
        url: data["url"],
        raw_payload: data
      )

      event.save!
    end

    def enqueue_next_page(next_url)
      BillettoIngestEventsJob
        .set(wait: 2.seconds)
        .perform_later(url: next_url)
    end

    def parse_time(value)
      Time.zone.parse(value) if value.present?
    rescue ArgumentError
      nil
    end

    def clean(text)
      text&.strip
    end
  end
end
