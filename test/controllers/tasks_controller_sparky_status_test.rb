# ============================================================================
# Test: TasksController Sparky Status Helper
# ============================================================================
#
# These tests verify the fetch_sparky_status helper method returns
# live data from the database and properly indicates stale file data.
#
# ============================================================================

require "test_helper"
require "json"

class TasksControllerSparkyStatusTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
    # Create a test user and sign in before each test
    @user = User.create!(
      email: "test_sparky_status@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "testuser_sparky",
      name: "Test User",
      role: "user"
    )
    sign_in @user
    
    # Create tasks for testing
    @sprint_task = Task.create!(
      title: "Sprint Task for Status Test",
      assignee: "sparky",
      status: "sprint",
      priority: "high"
    )
    
    @in_progress_task = Task.create!(
      title: "In Progress Task for Status Test",
      assignee: "sparky",
      status: "in_progress",
      priority: "medium"
    )
    
    # Create mock usage log data
    @mock_usage_data = {
      "sessions" => [
        {
          "timestamp" => 30.minutes.ago.iso8601,
          "context_pct" => 42,
          "model" => "moonshot/kimi-k2.5",
          "note" => "Test session - stale"
        }
      ]
    }
  end

  # ==========================================================================
  # FETCH_SPARKY_STATUS TESTS
  # ==========================================================================

  test "fetch_sparky_status returns current sprint task" do
    # Touch sprint task to make it most recent
    @sprint_task.touch
    
    get tasks_url
    assert_response :success
    
    # The status card should show the sprint task
    assert_select '#sparky-status', /Sprint Task for Status Test/
    assert_select '#sparky-status', /Sprint/
  end

  test "fetch_sparky_status returns in_progress task when no sprint" do
    # Move sprint task to done
    @sprint_task.update!(status: 'done')
    
    get tasks_url
    assert_response :success
    
    # Should now show the in_progress task
    assert_select '#sparky-status', /In Progress Task for Status Test/
    assert_select '#sparky-status', /In Progress/
  end

  test "fetch_sparky_status indicates idle when no active tasks" do
    Task.where(assignee: 'sparky').destroy_all
    
    get tasks_url
    assert_response :success
    
    assert_select '#sparky-status', /Idle/
  end

  test "fetch_sparky_status includes context data" do
    # Create a mock usage log file
    log_path = Rails.root.join("..", "memory", "usage-log.json")
    original_content = File.exist?(log_path) ? File.read(log_path) : nil
    
    begin
      FileUtils.mkdir_p(File.dirname(log_path))
      File.write(log_path, @mock_usage_data.to_json)
      
      get tasks_url
      assert_response :success
      
      # Should show context percentage
      assert_select '#sparky-status .progress-bar'
      
    ensure
      # Restore original content
      if original_content
        File.write(log_path, original_content)
      elsif File.exist?(log_path)
        File.delete(log_path)
      end
    end
  end

  test "fetch_sparky_status marks data as stale when file is old" do
    # Create a stale usage log (older than 30 minutes)
    log_path = Rails.root.join("..", "memory", "usage-log.json")
    original_content = File.exist?(log_path) ? File.read(log_path) : nil
    
    stale_data = {
      "sessions" => [
        {
          "timestamp" => 35.minutes.ago.iso8601,
          "context_pct" => 50,
          "model" => "moonshot/kimi-k2.5"
        }
      ]
    }
    
    begin
      FileUtils.mkdir_p(File.dirname(log_path))
      File.write(log_path, stale_data.to_json)
      
      get tasks_url
      assert_response :success
      
      # Should indicate stale data warning
      assert_select '#sparky-status', /Stale data/
      
    ensure
      if original_content
        File.write(log_path, original_content)
      elsif File.exist?(log_path)
        File.delete(log_path)
      end
    end
  end

  test "fetch_sparky_status shows is_active when task is current" do
    # Touch task to make it recent
    @sprint_task.touch
    
    get tasks_url
    assert_response :success
    
    # Should show active status (Animated badge)
    assert_select '#sparky-status', /Animated/
  end

  test "fetch_sparky_status includes model information" do
    get tasks_url
    assert_response :success
    
    # Should show model name (or "Unknown" if no data)
    assert_select '#sparky-status', /Model/
  end

  test "fetch_sparky_status includes timestamp" do
    get tasks_url
    assert_response :success
    
    # Should show "ago" timestamp
    assert_select '#sparky-status', /ago/
  end

  test "fetch_sparky_status uses database activity for last_activity_at" do
    # Update task to set a specific time
    @sprint_task.update!(updated_at: 5.minutes.ago)
    
    get tasks_url
    assert_response :success
    
    # The view should reflect recent activity (within last 10 minutes = active)
    assert_select '#sparky-status', /Animated/
  end

  test "fetch_sparky_status handles missing usage log gracefully" do
    # Remove usage log if it exists
    log_path = Rails.root.join("..", "memory", "usage-log.json")
    original_content = File.exist?(log_path) ? File.read(log_path) : nil
    
    begin
      File.delete(log_path) if File.exist?(log_path)
      
      get tasks_url
      assert_response :success
      
      # Should still render without error
      assert_select '#sparky-status'
      
    ensure
      if original_content
        FileUtils.mkdir_p(File.dirname(log_path))
        File.write(log_path, original_content)
      end
    end
  end
end
