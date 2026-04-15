class EventsController < ApplicationController
  PER_PAGE = 20

  helper_method :current_user_id

  def index
    @page = current_page
    @events = paginated_events
    @vote_history_by_event_id = Event.vote_history_by_event_ids(@events.map(&:id))
    @total_pages = total_pages
  end

  private

  def paginated_events
    filtered_events
      .limit(PER_PAGE)
      .offset(offset)
  end

  def filtered_events
    if params[:show] == "all"
      Event.recent_first
    elsif params[:show] == "past"
      Event.past_event.recent_first
    else
      Event.upcoming.recent_first
    end
  end

  def current_page
    page = params[:page].to_i
    page > 0 ? page : 1
  end

  def offset
    (current_page - 1) * PER_PAGE
  end

  def total_pages
    (Event.count / PER_PAGE.to_f).ceil
  end
end
