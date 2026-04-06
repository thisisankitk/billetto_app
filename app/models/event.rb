class Event < ApplicationRecord
    validates :external_id, presence: true, uniqueness: true
    validates :title, presence: true

    scope :upcoming, -> { where("starts_at >= ?", Time.current) }
    scope :recent_first, -> { order(starts_at: :desc) }
end
