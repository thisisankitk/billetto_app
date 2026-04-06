class BillettoIngestEventsJob < ApplicationJob
  queue_as :default

  retry_on Billetto::Client::Error,
           wait: :exponentially_longer,
           attempts: 5

  retry_on StandardError,
           wait: 10.seconds,
           attempts: 3

  def perform(url: nil)
    Billetto::IngestEvents.new(
      url: url
    ).call(fetch_all: true)
  end
end