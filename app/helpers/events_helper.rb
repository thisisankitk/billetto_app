module EventsHelper
  def vote_history_rows_for(event, vote_history_by_event_id)
    vote_history_by_event_id.fetch(event.id.to_s, [])
  end
end
