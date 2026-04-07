require "rails_helper"

RSpec.describe "Votes", type: :request do
  let!(:event_record) do
    Event.create!(external_id: "evt-900", title: "Vote me")
  end

  describe "POST /events/:event_id/upvote" do
    context "when user is not authenticated" do
      let(:clerk) { instance_double("ClerkContext", session: nil, sign_in_url: "/sign-in") }

      before do
        allow_any_instance_of(ApplicationController).to receive(:clerk).and_return(clerk)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it "redirects to sign-in" do
        post "/events/#{event_record.id}/upvote"

        expect(response).to redirect_to("/sign-in")
      end
    end

    context "when user is authenticated" do
      let(:user) { Struct.new(:id).new("user_100") }
      let(:command_bus) { instance_double(Command::Bus) }
      let(:clerk) { instance_double("ClerkContext", session: true, sign_in_url: "/sign-in") }

      before do
        allow_any_instance_of(ApplicationController).to receive(:clerk).and_return(clerk)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        allow(Rails.configuration).to receive(:command_bus).and_return(command_bus)
      end

      it "dispatches Voting::UpvoteEvent through command bus" do
        expect(command_bus).to receive(:call) do |command|
          expect(command).to be_a(Voting::UpvoteEvent)
          expect(command.event_id).to eq(event_record.id.to_s)
          expect(command.user_id).to eq("user_100")
        end

        post "/events/#{event_record.id}/upvote"

        expect(response).to redirect_to(root_path)
      end

      it "shows an alert when user has already voted" do
        allow(command_bus).to receive(:call).and_raise(
          RubyEventStore::WrongExpectedEventVersion.new("already voted")
        )

        post "/events/#{event_record.id}/upvote"

        expect(response).to redirect_to(root_path)

        follow_redirect!

        expect(response.body).to include("You have already voted")
      end
    end
  end

  describe "POST /events/:event_id/downvote" do
    context "when user is not authenticated" do
      let(:clerk) { instance_double("ClerkContext", session: nil, sign_in_url: "/sign-in") }

      before do
        allow_any_instance_of(ApplicationController).to receive(:clerk).and_return(clerk)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it "redirects to sign-in" do
        post "/events/#{event_record.id}/downvote"

        expect(response).to redirect_to("/sign-in")
      end
    end

    context "when user is authenticated" do
      let(:user) { Struct.new(:id).new("user_101") }
      let(:command_bus) { instance_double(Command::Bus) }
      let(:clerk) { instance_double("ClerkContext", session: true, sign_in_url: "/sign-in") }

      before do
        allow_any_instance_of(ApplicationController).to receive(:clerk).and_return(clerk)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        allow(Rails.configuration).to receive(:command_bus).and_return(command_bus)
      end

      it "dispatches Voting::DownvoteEvent through command bus" do
        expect(command_bus).to receive(:call) do |command|
          expect(command).to be_a(Voting::DownvoteEvent)
          expect(command.event_id).to eq(event_record.id.to_s)
          expect(command.user_id).to eq("user_101")
        end

        post "/events/#{event_record.id}/downvote"

        expect(response).to redirect_to(root_path)
      end

      it "shows an alert when user has already voted" do
        allow(command_bus).to receive(:call).and_raise(
          RubyEventStore::WrongExpectedEventVersion.new("already voted")
        )

        post "/events/#{event_record.id}/downvote"

        expect(response).to redirect_to(root_path)

        follow_redirect!

        expect(response.body).to include("You have already voted")
      end
    end
  end
end
