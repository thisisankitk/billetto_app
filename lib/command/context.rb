require "active_support/current_attributes"

module Command
  class Context < ActiveSupport::CurrentAttributes
    attribute :correlation_id, :causation_id
  end
end
