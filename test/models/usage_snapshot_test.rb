# ============================================================================
# UsageSnapshot Model Tests
# ============================================================================
#
# Tests for the UsageSnapshot model which tracks AI API usage over time.
#
# ============================================================================

require "test_helper"

class UsageSnapshotTest < ActiveSupport::TestCase
  # ============================================================================
  # FIXTURES
  # ============================================================================
  
  def setup
    @valid_attrs = {
      daily_remaining: 75.5,
      weekly_remaining: 82.3,
      total_used: 15000,
      session_count: 5,
      ai_model: "claude-sonnet-4-5",
      recorded_at: Time.current
    }
  end

  # ============================================================================
  # VALIDATION TESTS
  # ============================================================================

  test "valid with all attributes" do
    snapshot = UsageSnapshot.new(@valid_attrs)
    assert snapshot.valid?, "Should be valid with all attributes"
  end

  test "valid with only recorded_at" do
    snapshot = UsageSnapshot.new(recorded_at: Time.current)
    assert snapshot.valid?, "Should be valid with just recorded_at"
  end

  test "auto-sets recorded_at if not provided" do
    snapshot = UsageSnapshot.new(daily_remaining: 50)
    assert_nil snapshot.recorded_at
    snapshot.valid? # Trigger callback
    assert_not_nil snapshot.recorded_at, "Should auto-set recorded_at"
  end

  test "invalid with negative daily_remaining" do
    snapshot = UsageSnapshot.new(@valid_attrs.merge(daily_remaining: -1))
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:daily_remaining], "must be greater than or equal to 0"
  end

  test "invalid with daily_remaining over 100" do
    snapshot = UsageSnapshot.new(@valid_attrs.merge(daily_remaining: 101))
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:daily_remaining], "must be less than or equal to 100"
  end

  test "invalid with negative weekly_remaining" do
    snapshot = UsageSnapshot.new(@valid_attrs.merge(weekly_remaining: -5))
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:weekly_remaining], "must be greater than or equal to 0"
  end

  test "invalid with weekly_remaining over 100" do
    snapshot = UsageSnapshot.new(@valid_attrs.merge(weekly_remaining: 150))
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:weekly_remaining], "must be less than or equal to 100"
  end

  test "allows nil for percentage fields" do
    snapshot = UsageSnapshot.new(@valid_attrs.merge(
      daily_remaining: nil,
      weekly_remaining: nil
    ))
    assert snapshot.valid?, "Should allow nil percentages"
  end

  test "invalid with negative total_used" do
    snapshot = UsageSnapshot.new(@valid_attrs.merge(total_used: -100))
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:total_used], "must be greater than or equal to 0"
  end

  test "invalid with negative session_count" do
    snapshot = UsageSnapshot.new(@valid_attrs.merge(session_count: -1))
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:session_count], "must be greater than or equal to 0"
  end

  test "invalid with non-integer session_count" do
    snapshot = UsageSnapshot.new(@valid_attrs.merge(session_count: 3.5))
    assert_not snapshot.valid?
    assert_includes snapshot.errors[:session_count], "must be an integer"
  end

  # ============================================================================
  # SCOPE TESTS
  # ============================================================================

  test "recent scope returns snapshots from last 7 days" do
    # Create old snapshot
    old = UsageSnapshot.create!(
      @valid_attrs.merge(recorded_at: 10.days.ago)
    )
    
    # Create recent snapshots
    recent1 = UsageSnapshot.create!(
      @valid_attrs.merge(recorded_at: 2.days.ago)
    )
    recent2 = UsageSnapshot.create!(
      @valid_attrs.merge(recorded_at: 1.day.ago)
    )

    results = UsageSnapshot.recent
    assert_includes results, recent1
    assert_includes results, recent2
    assert_not_includes results, old
  end

  test "today scope returns only today's snapshots" do
    yesterday = UsageSnapshot.create!(
      @valid_attrs.merge(recorded_at: 1.day.ago)
    )
    today = UsageSnapshot.create!(
      @valid_attrs.merge(recorded_at: Time.current)
    )

    results = UsageSnapshot.today
    assert_includes results, today
    assert_not_includes results, yesterday
  end

  test "this_week scope returns snapshots from past 7 days" do
    old = UsageSnapshot.create!(
      @valid_attrs.merge(recorded_at: 8.days.ago)
    )
    this_week = UsageSnapshot.create!(
      @valid_attrs.merge(recorded_at: 3.days.ago)
    )

    results = UsageSnapshot.this_week
    assert_includes results, this_week
    assert_not_includes results, old
  end

  # ============================================================================
  # EDGE CASES
  # ============================================================================

  test "handles very large total_used values" do
    snapshot = UsageSnapshot.new(@valid_attrs.merge(total_used: 1_000_000_000))
    assert snapshot.valid?
  end

  test "handles long ai_model names" do
    long_name = "a" * 255
    snapshot = UsageSnapshot.new(@valid_attrs.merge(ai_model: long_name))
    assert snapshot.valid?
  end

  test "handles decimal percentages precisely" do
    snapshot = UsageSnapshot.create!(
      @valid_attrs.merge(
        daily_remaining: 75.555555,
        weekly_remaining: 82.333333
      )
    )
    
    # Reload from database to verify precision
    snapshot.reload
    assert_in_delta 75.555555, snapshot.daily_remaining, 0.000001
    assert_in_delta 82.333333, snapshot.weekly_remaining, 0.000001
  end
end
