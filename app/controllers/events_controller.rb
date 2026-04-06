class EventsController < ApplicationController
  PER_PAGE = 20
  
  helper_method :current_user_id

  def index
    @page = current_page
    @events = paginated_events
    @total_pages = total_pages
  end

  private

  def paginated_events
    Event
      .recent_first
      .limit(PER_PAGE)
      .offset(offset)
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
