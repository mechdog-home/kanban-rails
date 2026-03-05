# ============================================================================
# UsageDashboardController Tests
# ============================================================================
#
# Tests for the UsageDashboard controller which displays AI usage
# statistics and charts.
#
# ============================================================================

require "test_helper"

class UsageDashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # ============================================================================
  # SETUP
  # ============================================================================

  def setup
    # Create a test user and sign in before each test
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "testuser",
      name: "Test User",
      role: "user"
    )
    sign_in @user
  end

  # ============================================================================
  # INDEX TESTS
  # ============================================================================

  test "should get index" do
    get usage_dashboard_url
    assert_response :success
    assert_select "h1", "AI Usage Tracker"
  end

  test "index requires authentication" do
    sign_out @user
    get usage_dashboard_url
    assert_redirected_to new_user_session_url
  end

  test "index displays statistics cards" do
    create_test_snapshots
    
    get usage_dashboard_url
    assert_response :success
    
    # Check for stat card headings
    assert_select "h6.card-title", text: "Total Snapshots"
    assert_select "h6.card-title", text: "Today's Remaining"
    assert_select "h6.card-title", text: "Weekly Remaining"
    assert_select "h6.card-title", text: "7-Day Avg (Daily)"
  end

  test "index displays chart containers when data exists" do
    create_test_snapshots
    
    get usage_dashboard_url
    assert_response :success
    
    assert_select "canvas#dailyChart"
    assert_select "canvas#weeklyChart"
  end

  test "index shows empty state when no data" do
    get usage_dashboard_url
    assert_response :success
    
    assert_select ".alert-info", /No usage data recorded yet/
    assert_select "canvas#dailyChart", count: 0
  end

  test "index displays recent snapshots table" do
    create_test_snapshots(5)
    
    get usage_dashboard_url
    assert_response :success
    
    assert_select "h5", "Recent Snapshots"
    assert_select "table tbody tr", count: 5
  end

  test "index displays Log Current Usage button" do
    get usage_dashboard_url
    assert_response :success
    
    assert_select "a.btn-primary", "Log Current Usage"
  end

  # ============================================================================
  # CHART DATA TESTS
  # ============================================================================

  test "chart data is properly grouped by date" do
    # Create multiple snapshots on same day - only last should be used
    today = Date.current
    UsageSnapshot.create!(daily_remaining: 50, weekly_remaining: 60, recorded_at: today.to_time)
    UsageSnapshot.create!(daily_remaining: 75, weekly_remaining: 80, recorded_at: today.to_time + 1.hour)
    
    get usage_dashboard_url
    assert_response :success
    
    # Should use the last snapshot of the day (75, 80)
    # Chart data is passed to JavaScript, so we check it's in the page
    assert_match /75/, response.body
    assert_match /80/, response.body
  end

  # ============================================================================
  # STATS CALCULATION TESTS
  # ============================================================================

  test "stats calculate correctly with data" do
    UsageSnapshot.create!(daily_remaining: 80, weekly_remaining: 85, recorded_at: Time.current)
    UsageSnapshot.create!(daily_remaining: 70, weekly_remaining: 75, recorded_at: 1.day.ago)
    
    get usage_dashboard_url
    assert_response :success
    
    # Total snapshots should be 2
    assert_match /2/, response.body
  end

  test "stats show N/A when no data" do
    get usage_dashboard_url
    assert_response :success
    
    assert_match /N\/A/, response.body
  end

  # ============================================================================
  # NAVIGATION TESTS
  # ============================================================================

  test "navbar includes Usage link" do
    get usage_dashboard_url
    assert_response :success
    
    assert_select "a.nav-link[href=?]", usage_dashboard_path do
      assert_select "i.bi-graph-up"
    end
  end

  # ============================================================================
  # HELPERS
  # ============================================================================

  private

  def create_test_snapshots(count = 3)
    count.times do |i|
      UsageSnapshot.create!(
        daily_remaining: 70 + i,
        weekly_remaining: 75 + i,
        total_used: 10000 * (i + 1),
        session_count: i + 1,
        ai_model: "model-#{i}",
        recorded_at: i.days.ago
      )
    end
  end
end
