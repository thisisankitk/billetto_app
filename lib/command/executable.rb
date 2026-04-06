require "active_support/concern"

module Command
  module Executable
    extend ActiveSupport::Concern

    included do
      include ActiveModel::Model
      include ActiveModel::Attributes
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end