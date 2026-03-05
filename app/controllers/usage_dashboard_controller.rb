# ============================================================================
# UsageDashboardController - AI Usage Tracking Dashboard
# ============================================================================
#
# LEARNING NOTES:
#
# This controller displays AI API usage over time. It helps identify
# usage patterns and understand budget needs.
#
# KEY CONCEPTS:
# - Uses Chart.js for visualizations (loaded via CDN)
# - Aggregates data from UsageSnapshot model
# - Shows daily and weekly remaining percentages
#
# ============================================================================

class UsageDashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Get snapshots for the last 30 days
    @snapshots = UsageSnapshot
                   .where("recorded_at >= ?", 30.days.ago)
                   .order(:recorded_at)

    # Calculate statistics
    @stats = calculate_stats(@snapshots)

    # Prepare chart data
    @chart_data = prepare_chart_data(@snapshots)
  end

  private

  def calculate_stats(snapshots)
    return default_stats if snapshots.empty?

    recent = snapshots.last(7)
    daily_avg = recent.map(&:daily_remaining).compact.sum / recent.size rescue 0
    weekly_avg = recent.map(&:weekly_remaining).compact.sum / recent.size rescue 0

    {
      total_snapshots: snapshots.count,
      daily_avg: daily_avg.round(2),
      weekly_avg: weekly_avg.round(2),
      today_remaining: snapshots.last&.daily_remaining || 0,
      this_week_remaining: snapshots.last&.weekly_remaining || 0,
      first_recorded: snapshots.first&.recorded_at&.strftime("%Y-%m-%d"),
      last_recorded: snapshots.last&.recorded_at&.strftime("%Y-%m-%d %H:%M")
    }
  end

  def default_stats
    {
      total_snapshots: 0,
      daily_avg: 0,
      weekly_avg: 0,
      today_remaining: 0,
      this_week_remaining: 0,
      first_recorded: nil,
      last_recorded: nil
    }
  end

  def prepare_chart_data(snapshots)
    return {} if snapshots.empty?

    # Group by date for cleaner charts
    by_date = snapshots.group_by { |s| s.recorded_at.to_date }
                       .transform_values { |arr| arr.last } # Take last snapshot of each day

    {
      labels: by_date.keys.map { |d| d.strftime("%m/%d") },
      daily: by_date.values.map(&:daily_remaining),
      weekly: by_date.values.map(&:weekly_remaining)
    }
  end
end
