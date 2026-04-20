class SendEventWebhookRequestJob < ApplicationJob
  queue_as :default

  retry_on StandardError,
           wait: 10.seconds,
           attempts: 3

  def perform(user_id, event_id)
    url = 'https://webhook.site/5fb61ee1-e033-4622-9571-d7cac31d6aa9'
    connection.post(url) do |request|
      request.headers['Content-Type'] = 'application/json'
      request.body = { message: "#{user_id} downvoted event #{event_id}" }.to_json
    end
  end

  def connection
    Faraday.new do |f|
      f.headers["Accept"] = "application/json"
    end
  end
end