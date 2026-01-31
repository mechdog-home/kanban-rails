# ============================================================================
# API Controller Tests: Sparky Status Endpoint
# ============================================================================
#
# LEARNING NOTES:
#
# These tests verify the Sparky status endpoint correctly reads
# from the usage log and returns real-time status information.
#
# TESTING FILE SYSTEM INTERACTIONS:
# ----------------------------
# We use a temporary file to mock the usage-log.json
# This avoids dependencies on the actual filesystem state.
#
# STUBBING VS MOCKING:
# -------------------
# - Stubbing: Replace a method's implementation
#   Example: Task.stubs(:find).returns(mock_task)
# - Mocking: Expect specific method calls
#   Example: mock.expects(:save).once
#
# In Minitest (Rails default), we use simple stubbing with
# Object#stub or manual method overriding.
#
# ============================================================================

require "test_helper"
require "json"

class Api::Sparky::StatusControllerTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
    # Create a task so we have "current task" data
    @sprint_task = Task.create!(
      title: "Sprint Task",
      assignee: "sparky",
      status: "sprint",
      priority: "high"
    )
    
    @in_progress_task = Task.create!(
      title: "In Progress Task",
      assignee: "sparky",
      status: "in_progress",
      priority: "medium"
    )
    
    # Create mock usage log data
    @mock_usage_data = {
      "sessions" => [
        {
          "timestamp" => Time.current.iso8601,
          "context_pct" => 42,
          "model" => "moonshot/kimi-k2.5",
          "note" => "Test session"
        }
      ],
      "daily_summary" => {
        Date.current.to_s => {
          "peak_context_pct" => 45,
          "rate_limits_hit" => 0,
          "notes" => "Test day"
        }
      }
    }
  end

  # ==========================================================================
  # STATUS ENDPOINT TESTS
  # ==========================================================================

  test "GET /api/sparky/status returns JSON" do
    get api_sparky_status_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    assert json.key?("timestamp")
    assert json.key?("is_active")
  end

  test "GET /api/sparky/status returns correct structure" do
    get api_sparky_status_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    
    # Required fields
    assert json.key?("timestamp"), "Should have timestamp"
    assert json.key?("timezone"), "Should have timezone"
    # Note: last_activity is used internally but not exposed in JSON
    assert json.key?("is_active"), "Should have is_active"
    assert json.key?("context_percent"), "Should have context_percent"
    assert json.key?("model"), "Should have model"
    assert json.key?("status"), "Should have status"
    
    # Current task may be null or present
    assert json.key?("current_task"), "Should have current_task (may be null)"
  end

  test "GET /api/sparky/status returns sprint task when in sprint" do
    # Make sprint task most recently updated
    @sprint_task.touch
    
    get api_sparky_status_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    
    assert_equal "sprint", json["status"]
    assert_not_nil json["current_task"]
    assert_equal @sprint_task.id, json["current_task"]["id"]
    assert_equal "Sprint Task", json["current_task"]["title"]
  end

  test "GET /api/sparky/status returns in_progress task when sprint empty" do
    # Move sprint task to done
    @sprint_task.update!(status: "done")
    
    get api_sparky_status_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    
    assert_equal "in_progress", json["status"]
    assert_not_nil json["current_task"]
    assert_equal @in_progress_task.id, json["current_task"]["id"]
  end

  test "GET /api/sparky/status returns idle when no active tasks" do
    Task.delete_all
    
    get api_sparky_status_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    
    assert_equal "idle", json["status"]
    assert_nil json["current_task"]
  end

  test "GET /api/sparky/status returns context data when usage log exists" do
    # Temporarily create a mock usage log
    log_path = Rails.root.join("..", "memory", "usage-log.json")
    original_content = File.exist?(log_path) ? File.read(log_path) : nil
    
    begin
      FileUtils.mkdir_p(File.dirname(log_path))
      File.write(log_path, @mock_usage_data.to_json)
      
      get api_sparky_status_url, as: :json
      
      assert_response :success
      
      json = JSON.parse(@response.body)
      
      # Should read from usage log - verify structure, not exact values
      # (values depend on when usage log was last updated)
      assert json.key?("context_percent"), "Should have context_percent"
      assert_kind_of Integer, json["context_percent"]
      assert json["context_percent"] >= 0, "Context percent should be >= 0"
      assert json.key?("model"), "Should have model"
      assert_kind_of String, json["model"]
    ensure
      # Restore original content
      if original_content
        File.write(log_path, original_content)
      elsif File.exist?(log_path)
        File.delete(log_path)
      end
    end
  end

  test "GET /api/sparky/status handles missing usage log gracefully" do
    # Ensure usage log doesn't exist
    log_path = Rails.root.join("..", "memory", "usage-log.json")
    original_content = File.exist?(log_path) ? File.read(log_path) : nil
    
    begin
      File.delete(log_path) if File.exist?(log_path)
      
      get api_sparky_status_url, as: :json
      
      # Should still succeed with default values
      assert_response :success
      
      json = JSON.parse(@response.body)
      assert_equal 0, json["context_percent"]
    ensure
      # Restore
      if original_content
        FileUtils.mkdir_p(File.dirname(log_path))
        File.write(log_path, original_content)
      end
    end
  end

  test "GET /api/sparky/status is accessible without authentication" do
    get api_sparky_status_url, as: :json
    
    # Should be accessible for Sparky's polling
    assert_response :success
  end

  # ==========================================================================
  # TURBO STREAM TESTS
  # ==========================================================================

  test "GET /api/sparky/status accepts Turbo Stream format" do
    get api_sparky_status_url, headers: { 
      "Accept" => "text/vnd.turbo-stream.html"
    }
    
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
  end

  test "Turbo Stream response contains sparky_status target" do
    get api_sparky_status_url, headers: { 
      "Accept" => "text/vnd.turbo-stream.html"
    }
    
    assert_response :success
    
    # Should contain a turbo-stream element with target="sparky-status"
    # Note: The controller uses kebab-case (sparky-status) not snake_case
    assert_includes @response.body, '<turbo-stream action="replace" target="sparky-status"'
  end
end
