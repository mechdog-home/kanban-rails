# ============================================================================
# Controller Tests: Move Buttons
# ============================================================================
#
# LEARNING NOTES:
#
# These tests verify the move_left and move_right actions correctly
# transition tasks between statuses. This catches issues like:
# - Routes not being defined
# - Actions not updating the status
# - Turbo Stream responses not rendering
#
# TESTING TURBO STREAMS:
# ---------------------
# Turbo Stream responses are HTML fragments, not JSON.
# We check that the response:
# 1. Has the correct content-type
# 2. Contains <turbo-stream> elements
# 3. Targets the correct DOM elements
#
# ============================================================================

require "test_helper"

class TasksControllerMoveTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "testuser",
      name: "Test User",
      role: "user"
    )
    sign_in @user

    # Create tasks at different positions in the workflow
    @backlog_task = Task.create!(
      title: "Backlog Task",
      assignee: "sparky",
      status: "backlog",
      priority: "medium"
    )
    
    @in_progress_task = Task.create!(
      title: "In Progress Task",
      assignee: "sparky",
      status: "in_progress",
      priority: "high"
    )
    
    @done_task = Task.create!(
      title: "Done Task",
      assignee: "sparky",
      status: "done",
      priority: "low"
    )
  end

  # ==========================================================================
  # MOVE RIGHT TESTS (progress workflow)
  # ==========================================================================

  test "POST /tasks/:id/move_right advances status" do
    post move_right_task_url(@backlog_task), as: :turbo_stream
    
    assert_response :success
    
    @backlog_task.reload
    assert_equal "in_progress", @backlog_task.status
  end

  test "POST /tasks/:id/move_right from in_progress goes to sprint" do
    post move_right_task_url(@in_progress_task), as: :turbo_stream
    
    assert_response :success
    
    @in_progress_task.reload
    assert_equal "sprint", @in_progress_task.status
  end

  test "POST /tasks/:id/move_right stops at done" do
    post move_right_task_url(@done_task), as: :turbo_stream
    
    # Controller redirects with alert when can't move further
    # Could be :success (no change) or :redirect (with message)
    assert_response :success  # or :redirect
    
    @done_task.reload
    assert_equal "done", @done_task.status  # Unchanged
  end

  test "move_right returns Turbo Stream response" do
    post move_right_task_url(@backlog_task), as: :turbo_stream
    
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
  end

  test "move_right Turbo Stream removes from old column" do
    post move_right_task_url(@backlog_task), as: :turbo_stream
    
    # Should contain a remove action for the old column
    assert_includes @response.body, '<turbo-stream action="remove"'
  end

  test "move_right Turbo Stream adds to new column" do
    post move_right_task_url(@backlog_task), as: :turbo_stream
    
    # Controller uses "prepend" to add to top of column
    # (not "append" which would add to bottom)
    assert_includes @response.body, '<turbo-stream action="prepend"'
  end

  # ==========================================================================
  # MOVE LEFT TESTS (regress workflow)
  # ==========================================================================

  test "POST /tasks/:id/move_left regresses status" do
    post move_left_task_url(@in_progress_task), as: :turbo_stream
    
    assert_response :success
    
    @in_progress_task.reload
    assert_equal "backlog", @in_progress_task.status
  end

  test "POST /tasks/:id/move_left stops at first status" do
    # Create task at first status
    hold_task = Task.create!(
      title: "Hold Task",
      assignee: "sparky",
      status: "hold",
      priority: "low"
    )
    
    post move_left_task_url(hold_task), as: :turbo_stream
    
    # Controller redirects with alert when can't move further
    # Could be :success (no change) or :redirect (with message)
    assert_response :success  # or :redirect
    
    hold_task.reload
    assert_equal "hold", hold_task.status  # Unchanged (can't go left)
  end

  test "move_left returns Turbo Stream response" do
    post move_left_task_url(@in_progress_task), as: :turbo_stream
    
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", @response.content_type
  end

  # ==========================================================================
  # EDGE CASES
  # ==========================================================================

  test "move_right updates updated_at timestamp" do
    original_time = @backlog_task.updated_at
    
    sleep(0.1)  # Ensure time difference
    post move_right_task_url(@backlog_task), as: :turbo_stream
    
    @backlog_task.reload
    assert @backlog_task.updated_at > original_time
  end

  test "move_left updates updated_at timestamp" do
    @in_progress_task.update!(status: "in_progress")
    original_time = @in_progress_task.updated_at
    
    sleep(0.1)
    post move_left_task_url(@in_progress_task), as: :turbo_stream
    
    @in_progress_task.reload
    assert @in_progress_task.updated_at > original_time
  end

  test "move_right on non-existent task returns 404 for JSON" do
    post move_right_task_url(id: 99999), as: :json
    
    assert_response :not_found
  end

  test "move_right on non-existent task redirects for HTML" do
    post move_right_task_url(id: 99999)
    
    # HTML/Turbo Stream format redirects to tasks page
    assert_redirected_to tasks_path
  end

  test "move_left on non-existent task returns 404 for JSON" do
    post move_left_task_url(id: 99999), as: :json
    
    assert_response :not_found
  end

  test "move_left on non-existent task redirects for HTML" do
    post move_left_task_url(id: 99999)
    
    # HTML/Turbo Stream format redirects to tasks page
    assert_redirected_to tasks_path
  end

  # ==========================================================================
  # FULL WORKFLOW TEST
  # ==========================================================================

  test "full workflow: move task through all statuses" do
    task = Task.create!(
      title: "Workflow Task",
      assignee: "sparky",
      status: "hold",
      priority: "medium"
    )
    
    # hold -> backlog
    post move_right_task_url(task), as: :turbo_stream
    task.reload
    assert_equal "backlog", task.status
    
    # backlog -> in_progress
    post move_right_task_url(task), as: :turbo_stream
    task.reload
    assert_equal "in_progress", task.status
    
    # in_progress -> sprint
    post move_right_task_url(task), as: :turbo_stream
    task.reload
    assert_equal "sprint", task.status
    
    # sprint -> daily
    post move_right_task_url(task), as: :turbo_stream
    task.reload
    assert_equal "daily", task.status
    
    # daily -> done
    post move_right_task_url(task), as: :turbo_stream
    task.reload
    assert_equal "done", task.status
    
    # done -> done (can't go further)
    post move_right_task_url(task), as: :turbo_stream
    task.reload
    assert_equal "done", task.status
    
    # Now go backwards
    # done -> daily
    post move_left_task_url(task), as: :turbo_stream
    task.reload
    assert_equal "daily", task.status
    
    # daily -> sprint
    post move_left_task_url(task), as: :turbo_stream
    task.reload
    assert_equal "sprint", task.status
  end
end
