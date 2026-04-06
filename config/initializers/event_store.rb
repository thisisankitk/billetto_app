require "rails_event_store"

Rails.configuration.event_store = RailsEventStore::Client.new

Rails.application.config.after_initialize do
  store = Rails.configuration.event_store
  handler = Voting::ReadModels::EventVotes.new

  store.subscribe(handler, to: [Voting::EventUpvoted])
  store.subscribe(handler, to: [Voting::EventDownvoted])
end