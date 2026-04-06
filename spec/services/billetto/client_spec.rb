require "rails_helper"

RSpec.describe Billetto::Client do
  before do
    allow(Rails.application.credentials).to receive(:dig).and_call_original
    allow(Rails.application.credentials)
      .to receive(:dig).with(:billetto, :access_key_id).and_return("access-key")
    allow(Rails.application.credentials)
      .to receive(:dig).with(:billetto, :access_key_secret).and_return("access-secret")
  end

  describe "#fetch_events" do
    it "returns parsed event list and pagination keys" do
      client = described_class.new(url: "/api/v3/public/events?limit=1")
      response = instance_double(
        Faraday::Response,
        body: {
          data: [ { "id" => "evt-1" } ],
          next_url: "/api/v3/public/events?page=2",
          has_more: true
        }.to_json
      )
      connection = instance_double(Faraday::Connection)
      allow(connection)
        .to receive(:get).with("/api/v3/public/events?limit=1").and_return(response)
      client.instance_variable_set(:@connection, connection)

      result = client.fetch_events

      expect(result).to eq(
        events: [ { "id" => "evt-1" } ],
        next_url: "/api/v3/public/events?page=2",
        has_more: true
      )
    end

    it "raises Billetto::Client::Error on Faraday failures" do
      client = described_class.new(url: "/api/v3/public/events?limit=1")
      connection = instance_double(Faraday::Connection)
      allow(connection)
        .to receive(:get)
        .and_raise(Faraday::ConnectionFailed.new("network down"))
      client.instance_variable_set(:@connection, connection)

      expect { client.fetch_events }
        .to raise_error(Billetto::Client::Error, /Failed to fetch events/)
    end

    it "raises Billetto::Client::Error on invalid JSON" do
      client = described_class.new(url: "/api/v3/public/events?limit=1")
      response = instance_double(Faraday::Response, body: "{bad json}")
      connection = instance_double(Faraday::Connection)
      allow(connection).to receive(:get).and_return(response)
      client.instance_variable_set(:@connection, connection)

      expect { client.fetch_events }
        .to raise_error(Billetto::Client::Error, /Invalid JSON response/)
    end
  end
end
