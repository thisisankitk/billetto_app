# Event Voting Application

Rails application that ingests and displays public Billetto events, supports authenticated voting, and records votes via Rails Event Store.

## Assignment Coverage

- Billetto API ingestion with validation and resilient error handling
- Event listing page with pagination and vote counters
- Clerk authentication integrated in Rails
- Voting implemented as domain events through Rails Event Store
- Test suite added with RSpec (model, request, domain, service, job, and system coverage)

## Tech Stack

- Ruby on Rails 8.1
- PostgreSQL
- Rails Event Store
- Clerk Ruby SDK + Clerk browser widget
- Faraday
- RSpec + Capybara

## Project Structure

- API client and ingestion:
	- app/services/billetto/client.rb
	- app/services/billetto/ingest_events.rb
	- app/jobs/billetto_ingest_events_job.rb
- Voting domain and read model:
	- app/domain/fact.rb
	- app/domain/voting/upvote_event.rb
	- app/domain/voting/downvote_event.rb
	- app/domain/voting/event_upvoted.rb
	- app/domain/voting/event_downvoted.rb
	- app/domain/voting/read_models/event_votes.rb
- Auth and controllers:
	- app/controllers/application_controller.rb
	- app/controllers/events_controller.rb
	- app/controllers/votes_controller.rb
	- app/controllers/sessions_controller.rb
	- app/controllers/registrations_controller.rb
- Wiring:
	- config/initializers/clerk.rb
	- config/initializers/event_store.rb
	- config/initializers/command_bus.rb

## Prerequisites

- Ruby 3.x
- Bundler
- PostgreSQL 14+

## Setup

1. Install dependencies

```bash
bundle install
```

2. Configure credentials

```bash
bin/rails credentials:edit
```

Add at least:

```yml
clerk:
	secret_key: your_clerk_secret_key
	publishable_key: your_clerk_publishable_key
	frontend_api: your_clerk_frontend_api

billetto:
	access_key_id: your_billetto_access_key_id
	access_key_secret: your_billetto_access_key_secret
```

3. Prepare database

```bash
bin/rails db:prepare
```

4. Start app

```bash
bin/dev
```

Then open http://localhost:3000

## Billetto API Ingestion

- Fetch endpoint: GET /api/v3/public/events on billetto.dk
- Authentication header used in the client: Api-Keypair with access_key_id:access_key_secret
- Pagination handled with next_url and has_more
- Ingestion strategy:
	- Upsert Event by external_id
	- Clean text fields
	- Parse dates safely
	- Keep full raw payload for traceability

Run ingestion once:

```bash
bin/rails runner "Billetto::IngestEvents.new.call(fetch_all: true)"
```

Or enqueue background ingestion:

```bash
bin/rails runner "BillettoIngestEventsJob.perform_later"
```

## Authentication (Clerk)

- Clerk middleware is enabled in config/application.rb
- Clerk SDK configured in config/initializers/clerk.rb
- Controller helper is enabled via Clerk::Authenticatable
- Sign-in and sign-up pages mount Clerk widgets in:
	- app/views/sessions/new.html.erb
	- app/views/registrations/new.html.erb
- Voting routes are protected with authenticate_user! in VotesController

## Rails Event Store Voting

- Commands:
	- Voting::UpvoteEvent
	- Voting::DownvoteEvent
- Facts:
	- Voting::EventUpvoted
	- Voting::EventDownvoted
- Stream strategy:
	- Write vote to User$<user_id>$Event$<event_id>
	- expected_version: :none prevents duplicate votes per user-event pair
- Read model updates:
	- Voting::ReadModels::EventVotes increments Event.upvotes_count or Event.downvotes_count
- Subscriptions are wired in config/initializers/event_store.rb

## Running Tests

Run full RSpec suite:

```bash
bundle exec rspec
```

Run specific areas:

```bash
bundle exec rspec spec/models
bundle exec rspec spec/requests
bundle exec rspec spec/domain
bundle exec rspec spec/system
```

## Useful Commands

```bash
bin/rails c
bin/rails routes
bin/rails db:migrate
bin/rubocop
```

