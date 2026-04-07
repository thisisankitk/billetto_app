require "rails_event_store"
require Rails.root.join("lib/application_subscriptions")

Rails.configuration.event_store = RailsEventStore::Client.new

Rails.application.config.after_initialize do
  store = Rails.configuration.event_store

  ApplicationSubscriptions.handlers.each do |event_class, subscribers|
    Array(subscribers).each do |subscriber|
      store.subscribe(subscriber, to: [ event_class ])
    end
  end
end