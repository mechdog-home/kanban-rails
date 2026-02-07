# ============================================================================
# Model: ApiBalanceHistory
# ============================================================================
#
# Stores snapshots of AI provider API balances for tracking and monitoring.
#
# KEY CONCEPTS:
# - Tracks balance history over time
# - Supports multiple providers
# - Stores metadata for provider-specific details
#
# ============================================================================

class ApiBalanceHistory < ApplicationRecord
  # ==========================================================================
  # CONSTANTS
  # ==========================================================================
  
  # Supported AI providers
  PROVIDERS = %w[moonshot anthropic openai xai openrouter].freeze
  
  # Default currency
  DEFAULT_CURRENCY = 'USD'.freeze

  # ==========================================================================
  # VALIDATIONS
  # ==========================================================================
  
  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validates :queried_at, presence: true

  # ==========================================================================
  # SCOPES
  # ==========================================================================
  
  # Get records for a specific provider
  scope :for_provider, ->(provider) { where(provider: provider) }
  
  # Get successful queries only
  scope :successful, -> { where(success: true) }
  
  # Get recent records first
  scope :recent, -> { order(queried_at: :desc) }
  
  # Get the latest record for each provider
  # Note: Uses SQLite-compatible subquery instead of DISTINCT ON
  scope :latest_per_provider, -> {
    where(id: select('MAX(id)').group(:provider))
      .order(:provider)
  }
  
  # Get records from the last N hours
  scope :since, ->(hours_ago) { where('queried_at > ?', hours_ago.hours.ago) }
  
  # Get records for charting (last 7 days)
  scope :for_charting, ->(days = 7) {
    where('queried_at > ?', days.days.ago)
      .order(:queried_at)
  }

  # ==========================================================================
  # CLASS METHODS
  # ==========================================================================
  
  # Get the latest balance for each provider
  # Returns a hash: { 'moonshot' => { balance: 100.0, ... }, ... }
  def self.latest_balances
    latest_per_provider.index_by(&:provider).transform_values do |record|
      {
        balance: record.balance,
        currency: record.currency,
        success: record.success,
        error_message: record.error_message,
        queried_at: record.queried_at,
        metadata: record.metadata
      }
    end
  end
  
  # Get balance history for a provider over time
  # Returns array of { timestamp, balance } hashes
  def self.history_for(provider, days = 7)
    for_provider(provider)
      .successful
      .for_charting(days)
      .pluck(:queried_at, :balance)
      .map { |timestamp, balance| { timestamp: timestamp, balance: balance } }
  end
  
  # Calculate usage statistics for a provider
  def self.usage_stats(provider, days = 7)
    records = for_provider(provider).successful.since(days * 24).order(:queried_at)
    
    return nil if records.count < 2
    
    first_record = records.first
    last_record = records.last
    
    {
      start_balance: first_record.balance,
      end_balance: last_record.balance,
      spent: first_record.balance - last_record.balance,
      days_tracked: (last_record.queried_at - first_record.queried_at) / 1.day,
      average_daily_spend: (first_record.balance - last_record.balance) / [(last_record.queried_at - first_record.queried_at) / 1.day, 1].max
    }
  end

  # ==========================================================================
  # INSTANCE METHODS
  # ==========================================================================
  
  # Format balance for display
  def formatted_balance
    "$#{balance.round(2)} #{currency}"
  end
  
  # Check if this is a fresh record (within last hour)
  def fresh?
    queried_at > 1.hour.ago
  end
  
  # Human-readable time ago
  def time_ago
    time_ago = Time.current - queried_at
    
    if time_ago < 1.minute
      'just now'
    elsif time_ago < 1.hour
      "#{ (time_ago / 1.minute).round }m ago"
    elsif time_ago < 1.day
      "#{ (time_ago / 1.hour).round }h ago"
    else
      "#{ (time_ago / 1.day).round }d ago"
    end
  end
end
