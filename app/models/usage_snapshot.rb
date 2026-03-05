# ============================================================================
# UsageSnapshot Model - Stores AI API usage data
# ============================================================================
#
# Tracks daily and weekly remaining percentages to visualize usage patterns
# over time.
#
# ATTRIBUTES:
# - daily_remaining: Decimal (percentage, 0-100)
# - weekly_remaining: Decimal (percentage, 0-100)
# - total_used: Integer (total tokens used in session)
# - session_count: Integer (number of sessions)
# - ai_model: String (name of the AI model)
# - recorded_at: DateTime (when the snapshot was taken)
#
# ============================================================================

class UsageSnapshot < ApplicationRecord
  # Validations
  validates :recorded_at, presence: true
  validates :daily_remaining, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100,
    allow_nil: true 
  }
  validates :weekly_remaining, numericality: { 
    greater_than_or_equal_to: 0, 
    less_than_or_equal_to: 100,
    allow_nil: true 
  }
  validates :total_used, numericality: { 
    greater_than_or_equal_to: 0,
    allow_nil: true 
  }
  validates :session_count, numericality: { 
    greater_than_or_equal_to: 0,
    only_integer: true,
    allow_nil: true 
  }

  # Scopes
  scope :recent, -> { where("recorded_at >= ?", 7.days.ago).order(:recorded_at) }
  scope :today, -> { where(recorded_at: Date.current.all_day) }
  scope :this_week, -> { where("recorded_at >= ?", 7.days.ago.beginning_of_day) }

  # Callbacks
  before_validation :set_recorded_at, on: :create

  private

  def set_recorded_at
    self.recorded_at ||= Time.current
  end
end
