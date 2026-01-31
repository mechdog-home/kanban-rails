# ============================================================================
# API Controller Tests: Stats Endpoint
# ============================================================================
#
# LEARNING NOTES:
#
# These tests ensure the /api/stats endpoint returns the correct
# aggregation data for the kanban board dashboard.
#
# NEW FEATURE TESTING:
# -------------------
# When adding new endpoints, always test:
# 1. Happy path - returns expected data
# 2. Edge cases - empty database, invalid params
# 3. Response format - JSON structure matches contract
#
# TDD APPROACH:
# -------------
# If we had written these tests FIRST (Test Driven Development),
# the syntax error in the view would have been caught because
# we would have tested the full request cycle.
#
# ============================================================================

require "test_helper"

class Api::StatsControllerTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
    # Clear tasks to start fresh
    Task.delete_all
    
    # Create test data with different assignees and statuses
    @mechdog_backlog = Task.create!(title: "M Backlog", assignee: "mechdog", status: "backlog", priority: "medium")
    @mechdog_progress = Task.create!(title: "M Progress", assignee: "mechdog", status: "in_progress", priority: "high")
    @mechdog_done = Task.create!(title: "M Done", assignee: "mechdog", status: "done", priority: "low")
    
    @sparky_backlog = Task.create!(title: "S Backlog", assignee: "sparky", status: "backlog", priority: "medium")
    @sparky_sprint = Task.create!(title: "S Sprint", assignee: "sparky", status: "sprint", priority: "high")
    @sparky_daily = Task.create!(title: "S Daily", assignee: "sparky", status: "daily", priority: "low")
    @sparky_done = Task.create!(title: "S Done", assignee: "sparky", status: "done", priority: "medium")
  end

  # ==========================================================================
  # STATS ENDPOINT TESTS
  # ==========================================================================

  test "GET /api/stats returns total task count" do
    get api_stats_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    assert_equal 7, json["total"], "Should count all tasks"
  end

  test "GET /api/stats returns counts by assignee" do
    get api_stats_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    
    # Check structure exists (camelCase to match Node.js format)
    assert json.key?("byAssignee"), "Response should have byAssignee key"
    
    # Check counts
    assert_equal 3, json["byAssignee"]["mechdog"], "MechDog should have 3 tasks"
    assert_equal 4, json["byAssignee"]["sparky"], "Sparky should have 4 tasks"
  end

  test "GET /api/stats returns counts by status" do
    get api_stats_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    
    # Check structure exists (camelCase to match Node.js format)
    assert json.key?("byStatus"), "Response should have byStatus key"
    
    # Check counts for each status
    assert_equal 2, json["byStatus"]["backlog"], "Should have 2 backlog tasks"
    assert_equal 1, json["byStatus"]["in_progress"], "Should have 1 in_progress task"
    assert_equal 1, json["byStatus"]["sprint"], "Should have 1 sprint task"
    assert_equal 1, json["byStatus"]["daily"], "Should have 1 daily task"
    assert_equal 2, json["byStatus"]["done"], "Should have 2 done tasks"
    assert_equal 0, json["byStatus"]["hold"], "Should have 0 hold tasks"
  end

  test "GET /api/stats returns correct JSON structure" do
    get api_stats_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    
    # Verify exact structure matches Node.js format (camelCase)
    assert json.key?("total"), "Should have total key"
    assert json.key?("byAssignee"), "Should have byAssignee key"
    assert json.key?("byStatus"), "Should have byStatus key"
    
    # Verify types
    assert_kind_of Integer, json["total"]
    assert_kind_of Hash, json["byAssignee"]
    assert_kind_of Hash, json["byStatus"]
  end

  test "GET /api/stats handles empty database" do
    Task.delete_all
    
    get api_stats_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    assert_equal 0, json["total"]
    assert_equal 0, json["byAssignee"]["mechdog"]
    assert_equal 0, json["byAssignee"]["sparky"]
    # Verify all statuses are present and zero
    assert json["byStatus"].key?("backlog")
    assert json["byStatus"].key?("in_progress")
    assert json["byStatus"].key?("sprint")
    assert json["byStatus"].key?("daily")
    assert json["byStatus"].key?("hold")
    assert json["byStatus"].key?("done")
  end

  test "GET /api/stats is accessible without authentication" do
    # Sign out to test unauthenticated access
    sign_out :user if @controller.try(:user_signed_in?)
    
    get api_stats_url, as: :json
    
    # API endpoints should be accessible without login
    # (for Sparky's heartbeat checks)
    assert_response :success
  end
end
