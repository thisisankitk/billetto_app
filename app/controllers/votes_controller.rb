class VotesController < ApplicationController
  before_action :authenticate_user!

  def upvote
    cast_vote(Voting::UpvoteEvent)
  end

  def downvote
    cast_vote(Voting::DownvoteEvent)
  end

  private

  def cast_vote(command_class)
    command_bus.call(
      command_class.new(
        event_id: params[:event_id],
        user_id: current_user.id
      )
    )

    redirect_back fallback_location: root_path

  rescue RubyEventStore::WrongExpectedEventVersion
    flash[:alert] = "Your vote changed while processing. Please try again."
    redirect_back fallback_location: root_path
  end

  def command_bus
    Rails.configuration.command_bus
  end
end
