# ============================================================================
# API::UsageSnapshotsController Tests
# ============================================================================
#
# Tests for the UsageSnapshots API controller which records and retrieves
# AI usage data.
#
# ============================================================================

require "test_helper"

class Api::UsageSnapshotsControllerTest < ActionDispatch::IntegrationTest
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
    
    @valid_params = {
      usage_snapshot: {
        daily_remaining: 75.5,
        weekly_remaining: 82.3,
        total_used: 15000,
        session_count: 5,
        ai_model: "claude-sonnet-4-5",
        recorded_at: Time.current.iso8601
      }
    }
  end

  # ============================================================================
  # INDEX TESTS
  # ============================================================================

  test "should get index" do
    create_snapshots(3)
    
    get api_usage_snapshots_url, as: :json
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal 3, json["snapshots"].length
    assert_equal 3, json["count"]
  end

  test "index returns snapshots in descending order" do
    old = UsageSnapshot.create!(
      daily_remaining: 50,
      recorded_at: 5.days.ago
    )
    recent = UsageSnapshot.create!(
      daily_remaining: 75,
      recorded_at: Time.current
    )
    
    get api_usage_snapshots_url, as: :json
    json = JSON.parse(response.body)
    
    # Most recent should be first
    assert_equal recent.id, json["snapshots"].first["id"]
  end

  test "index limits to last 30 days" do
    old = UsageSnapshot.create!(
      daily_remaining: 50,
      recorded_at: 35.days.ago
    )
    recent = UsageSnapshot.create!(
      daily_remaining: 75,
      recorded_at: Time.current
    )
    
    get api_usage_snapshots_url, as: :json
    json = JSON.parse(response.body)
    
    assert_equal 1, json["count"]
    assert_equal recent.id, json["snapshots"].first["id"]
  end

  test "index requires authentication" do
    sign_out @user
    get api_usage_snapshots_url, as: :json
    assert_response :unauthorized
  end

  # ============================================================================
  # SHOW TESTS
  # ============================================================================

  test "should show snapshot" do
    snapshot = UsageSnapshot.create!(
      daily_remaining: 75.5,
      weekly_remaining: 82.3,
      recorded_at: Time.current
    )
    
    get api_usage_snapshot_url(snapshot), as: :json
    assert_response :success
    
    json = JSON.parse(response.body)
    assert_equal 75.5, json["snapshot"]["daily_remaining"]
    assert_equal 82.3, json["snapshot"]["weekly_remaining"]
  end

  test "show returns 404 for non-existent snapshot" do
    get api_usage_snapshot_url(id: 99999), as: :json
    assert_response :not_found
    
    json = JSON.parse(response.body)
    assert_equal "Snapshot not found", json["error"]
  end

  # ============================================================================
  # CREATE TESTS
  # ============================================================================

  test "should create snapshot" do
    assert_difference("UsageSnapshot.count", 1) do
      post api_usage_snapshots_url, params: @valid_params, as: :json
    end
    
    assert_response :created
    
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 75.5, json["snapshot"]["daily_remaining"]
    assert_equal "Usage snapshot recorded successfully", json["message"]
  end

  test "create auto-sets recorded_at if not provided" do
    params = @valid_params.deep_dup
    params[:usage_snapshot].delete(:recorded_at)
    
    post api_usage_snapshots_url, params: params, as: :json
    assert_response :created
    
    json = JSON.parse(response.body)
    assert_not_nil json["snapshot"]["recorded_at"]
  end

  test "create with invalid data returns errors" do
    params = @valid_params.deep_dup
    params[:usage_snapshot][:daily_remaining] = 150 # Over 100
    
    post api_usage_snapshots_url, params: params, as: :json
    assert_response :unprocessable_entity
    
    json = JSON.parse(response.body)
    assert_not json["success"]
    assert json["errors"].any? { |e| e.include?("less than or equal to 100") }
  end

  test "create requires authentication" do
    sign_out @user
    
    assert_no_difference("UsageSnapshot.count") do
      post api_usage_snapshots_url, params: @valid_params, as: :json
    end
    
    assert_response :unauthorized
  end

  # ============================================================================
  # LOG_USAGE TESTS
  # ============================================================================

  test "should log usage via log_usage endpoint" do
    log_params = {
      daily_remaining: 60.0,
      weekly_remaining: 70.0,
      total_used: 25000,
      session_count: 10,
      ai_model: "gpt-4"
    }
    
    assert_difference("UsageSnapshot.count", 1) do
      post log_usage_api_usage_snapshots_url, params: log_params, as: :json
    end
    
    assert_response :created
    
    json = JSON.parse(response.body)
    assert json["success"]
    assert_equal 60.0, json["snapshot"]["daily_remaining"]
    assert_equal "gpt-4", json["snapshot"]["ai_model"]
  end

  test "log_usage auto-sets recorded_at" do
    post log_usage_api_usage_snapshots_url, params: {
      daily_remaining: 50.0
    }, as: :json
    
    assert_response :created
    json = JSON.parse(response.body)
    assert_not_nil json["snapshot"]["recorded_at"]
  end

  # ============================================================================
  # JSON FORMAT TESTS
  # ============================================================================

  test "snapshot json includes all fields" do
    snapshot = UsageSnapshot.create!(
      daily_remaining: 75.5555,
      weekly_remaining: 82.3333,
      total_used: 15000,
      session_count: 5,
      ai_model: "claude-sonnet",
      recorded_at: Time.current
    )
    
    get api_usage_snapshot_url(snapshot), as: :json
    json = JSON.parse(response.body)["snapshot"]
    
    assert_equal 75.56, json["daily_remaining"] # Rounded to 2 decimals
    assert_equal 82.33, json["weekly_remaining"]
    assert_equal 15000, json["total_used"]
    assert_equal 5, json["session_count"]
    assert_equal "claude-sonnet", json["ai_model"]
    assert_not_nil json["recorded_at"]
  end

  # ============================================================================
  # HELPERS
  # ============================================================================

  private

  def create_snapshots(count)
    count.times do |i|
      UsageSnapshot.create!(
        daily_remaining: rand(50..95),
        weekly_remaining: rand(50..95),
        recorded_at: i.days.ago
      )
    end
  end
end
