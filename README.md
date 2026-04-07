# Billetto Event Voting Application

Rails 8 application that fetches public events from Billetto, stores them locally, displays them with pagination, and lets authenticated users vote exactly once per event. Votes are recorded as immutable events using Rails Event Store.

## Assignment Status

Implemented:
- Billetto API ingestion with pagination and retry behavior
- Event listing page with vote counters and pagination
- Clerk authentication with sign-in, sign-up, and sign-out flow
- Voting modeled as commands plus domain events (event sourcing)
- Read model projection to keep vote counters on events table
- RSpec test suite across request, model, service, job, domain, and system layers

Open improvements:
- CI workflow still runs Rails test tasks (Minitest commands) and should be switched to RSpec commands
- Model-level validation can be tightened further for required event attributes such as start time and URL depending on business rules

## Tech Stack

- Ruby 3.4.4
- Rails 8.1
- PostgreSQL
- Rails Event Store
- Clerk Ruby SDK plus Clerk browser widgets
- Faraday for external API calls
- Solid Queue (Active Job backend)
- RSpec and Capybara

## Architecture Overview

### 1) Ingestion flow (Billetto -> local events table)

1. `BillettoIngestEventsJob` triggers ingestion and enables retries.
2. `Billetto::IngestEvents` asks `Billetto::Client` for one page of events.
3. Client performs authenticated HTTP request to Billetto public events endpoint.
4. Service upserts records by `external_id` and stores normalized fields plus raw payload.
5. If more pages exist, next page is enqueued as another job.

### 2) Voting flow (HTTP request -> command -> event store -> projection)

1. Authenticated user submits upvote or downvote action.
2. `VotesController` creates a command (`Voting::UpvoteEvent` or `Voting::DownvoteEvent`) and sends it through the command bus.
3. `Command::Bus` validates and executes command inside a database transaction, with correlation instrumentation.
4. Command publishes domain event (`Voting::EventUpvoted` or `Voting::EventDownvoted`) to stream `User$<user_id>$Event$<event_id>` with `expected_version: :none`.
5. Rails Event Store subscription invokes `Voting::ReadModels::EventVotes` to increment denormalized counters in `events.upvotes_count` or `events.downvotes_count`.
6. Duplicate vote attempts raise `WrongExpectedEventVersion` and controller shows user-facing alert.

## Key Endpoints

| Method | Path | Purpose | Auth Required |
|---|---|---|---|
| GET | / | Event list with pagination (`?page=`) | No |
| POST | /events/:event_id/upvote | Cast upvote | Yes |
| POST | /events/:event_id/downvote | Cast downvote | Yes |
| GET | /sign-in | Clerk sign-in page | No |
| GET | /sign-up | Clerk sign-up page | No |
| GET, DELETE | /sign-out | App-controlled sign-out page that calls Clerk signOut | Session-based |
| GET | /up | Health check | No |

## Data Model Notes

### events table

Stores Billetto event read model and denormalized vote counters.

Important columns:
- `external_id` (unique source identifier)
- `title`, `description`, `starts_at`, `ends_at`
- `city`, `venue_name`, `organiser_name`
- `price_cents`, `currency`
- `url`, `image_url`
- `raw_payload` (full source payload for traceability)
- `upvotes_count`, `downvotes_count` (projection output)

### Rails Event Store tables

- `event_store_events`
- `event_store_events_in_streams`

These store immutable domain events and stream links used for duplicate-vote protection and auditability.

## Main Code Areas

API and ingestion:
- `app/services/billetto/client.rb`
- `app/services/billetto/ingest_events.rb`
- `app/jobs/billetto_ingest_events_job.rb`

Domain and projections:
- `app/domain/fact.rb`
- `app/domain/voting/upvote_event.rb`
- `app/domain/voting/downvote_event.rb`
- `app/domain/voting/event_upvoted.rb`
- `app/domain/voting/event_downvoted.rb`
- `app/domain/voting/read_models/event_votes.rb`

Application wiring:
- `lib/command/bus.rb`
- `lib/command/context.rb`
- `lib/application_subscriptions.rb`
- `config/initializers/command_bus.rb`
- `config/initializers/event_store.rb`
- `config/initializers/clerk.rb`

Web layer:
- `app/controllers/events_controller.rb`
- `app/controllers/votes_controller.rb`
- `app/controllers/sessions_controller.rb`
- `app/controllers/registrations_controller.rb`
- `app/controllers/application_controller.rb`

## Authentication Design (Clerk)

- Rack middleware is enabled in `config/application.rb`.
- Controller auth comes from `Clerk::Authenticatable` in `ApplicationController`.
- `authenticate_user!` checks `clerk.session` and redirects to Clerk sign-in URL when needed.
- Sign-in and sign-up pages mount Clerk widgets in browser.
- Sign-out is handled by app route `/sign-out`, then JavaScript calls `Clerk.signOut()` and redirects back to sign-in.

## Setup

### Prerequisites

- Ruby 3.4.4
- PostgreSQL 14+
- Bundler

### 1. Install dependencies

```bash
bundle install
```

### 2. Configure Rails credentials

```bash
bin/rails credentials:edit
```

Add values:

```yml
clerk:
  secret_key: your_clerk_secret_key
  publishable_key: your_clerk_publishable_key
  frontend_api: your_clerk_frontend_api

billetto:
  access_key_id: your_billetto_access_key_id
  access_key_secret: your_billetto_access_key_secret
```

Environment defaults in app config:
- `CLERK_SIGN_IN_URL=/sign-in`
- `CLERK_SIGN_UP_URL=/sign-up`
- `CLERK_AFTER_SIGN_IN_URL=/`
- `CLERK_AFTER_SIGN_UP_URL=/`

### 3. Prepare databases

```bash
bin/rails db:prepare
```

### 4. Start development stack

```bash
bin/dev
```

Open http://localhost:3000

## Ingestion Commands

Run full ingestion now:

```bash
bin/rails runner "Billetto::IngestEvents.new.call(fetch_all: true)"
```

Or enqueue the background job:

```bash
bin/rails runner "BillettoIngestEventsJob.perform_later"
```

## Test Coverage

Run full suite:

```bash
bundle exec rspec
```

Useful targeted runs:

```bash
bundle exec rspec spec/requests
bundle exec rspec spec/services
bundle exec rspec spec/domain
bundle exec rspec spec/jobs
bundle exec rspec spec/system
```

Current suite covers:
- Auth redirects and page behavior
- Voting success and duplicate-vote handling
- Ingestion parsing, upserting, and error handling
- Job retry and pagination enqueue behavior
- Command bus validation/instrumentation behavior
- Event store subscriptions and read model projection

## Design Decisions and Trade-offs

- Votes are event-sourced to preserve audit history and enforce one-vote-per-user-per-event at stream level.
- Event list uses denormalized counters for fast reads.
- Ingestion stores full raw payload for debugging and source-of-truth comparison.
- Command bus adds a central place for validation, transactions, and instrumentation.

## Useful Developer Commands

```bash
bin/rails c
bin/rails routes
bin/rails db:migrate
bin/rubocop
```

