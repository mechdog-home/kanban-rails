# ============================================================================
# Test: ApiBalanceHistory Model
# ============================================================================

require "test_helper"

class ApiBalanceHistoryTest < ActiveSupport::TestCase
  test "valid balance history record" do
    history = ApiBalanceHistory.new(
      provider: 'moonshot',
      balance: 100.50,
      currency: 'CNY',
      queried_at: Time.current,
      success: true
    )
    assert history.valid?
  end

  test "requires valid provider" do
    history = ApiBalanceHistory.new(
      provider: 'invalid_provider',
      balance: 100,
      queried_at: Time.current
    )
    assert_not history.valid?
    assert_includes history.errors[:provider], "is not included in the list"
  end

  test "requires non-negative balance" do
    history = ApiBalanceHistory.new(
      provider: 'moonshot',
      balance: -10,
      queried_at: Time.current
    )
    assert_not history.valid?
    assert_includes history.errors[:balance], "must be greater than or equal to 0"
  end

  test "formatted_balance with CNY" do
    history = ApiBalanceHistory.new(
      provider: 'moonshot',
      balance: 123.456,
      currency: 'CNY',
      queried_at: Time.current
    )
    assert_equal "$123.46 CNY", history.formatted_balance
  end

  test "fresh? returns true for recent records" do
    history = ApiBalanceHistory.new(
      provider: 'openrouter',
      balance: 50,
      queried_at: 30.minutes.ago
    )
    assert history.fresh?
  end

  test "fresh? returns false for old records" do
    history = ApiBalanceHistory.new(
      provider: 'openrouter',
      balance: 50,
      queried_at: 2.hours.ago
    )
    assert_not history.fresh?
  end
end
