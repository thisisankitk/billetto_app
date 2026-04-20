module Billetto
  class SendEventWebhookRequest
    def call(event)
      user_id = event.data[:user_id]
      event_id = event.data[:event_id]
      Rails.logger.info(
        "--------------------------------------".red
      )
      Rails.logger.info(
        {
          service: "event_service",
          action: "send_webhook",
          user_id: user_id,
          event_id: event_id,
          timestamp: event.metadata[:timestamp]
        }.to_json.green
      )
      Rails.logger.info(
        "--------------------------------------".red
      )
      SendEventWebhookRequestJob.perform_later(user_id, event_id)
    end
  end
end