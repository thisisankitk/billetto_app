module Billetto
  class Client
    BASE_URL = "https://billetto.dk"

    class Error < StandardError; end

    def initialize(url: nil)
      @url = url || "/api/v3/public/events?limit=10"
      @connection = build_connection
    end

    def fetch_events
      response = connection.get(url)
      parse_response(response)
    rescue Faraday::Error => e
      raise Error, "Failed to fetch events: #{e.message}"
    end

    private

    attr_reader :connection, :url

    def build_connection
      Faraday.new(url: BASE_URL) do |f|
        f.request :json
        f.response :raise_error

        f.headers['Api-Keypair'] = api_keypair
        f.headers['Accept'] = 'application/json'
      end
    end

    def api_keypair
      key = Rails.application.credentials.dig(:billetto, :access_key_id)
      secret = Rails.application.credentials.dig(:billetto, :access_key_secret)

      raise Error, "Missing API credentials" if key.blank? || secret.blank?

      "#{key}:#{secret}"
    end

    def parse_response(response)
      body = JSON.parse(response.body)

      {
        events: body.fetch("data"),
        next_url: body["next_url"],
        has_more: body.fetch("has_more")
      }
    rescue JSON::ParserError => e
      raise Error, "Invalid JSON response: #{e.message}"
    end
  end
end