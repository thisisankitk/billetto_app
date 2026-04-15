class VotesController < ApplicationController
  before_action :authenticate_user!

  def upvote
    command_bus.call(
      Voting::UpvoteEvent.new(
        event_id: params[:event_id],
        user_id: current_user.id
      )
    )

    redirect_to root_path

  rescue RubyEventStore::WrongExpectedEventVersion
    flash[:alert] = "You have already voted"
    redirect_to root_path
  end

  def downvote
    command_bus.call(
      Voting::DownvoteEvent.new(
        event_id: params[:event_id],
        user_id: current_user.id
      )
    )

    redirect_to root_path

  rescue RubyEventStore::WrongExpectedEventVersion
    flash[:alert] = "You have already voted"
    redirect_to root_path
  end

  private

  def command_bus
    Rails.configuration.command_bus
  end
end
