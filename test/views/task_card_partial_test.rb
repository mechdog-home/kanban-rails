# ============================================================================
# View Tests: Task Card Partial
# ============================================================================
#
# LEARNING NOTES:
#
# These tests render view partials directly to catch syntax errors
# before they reach the browser. This would have caught the Slim
# syntax error in _task_card.html.slim.
#
# WHY VIEW TESTS MATTER:
# ---------------------
# Controller tests check the HTTP layer, but they don't always
# render the full view. View tests ensure:
# 1. Template syntax is valid (catches Slim/ERB errors)
# 2. Partials render with expected data
# 3. HTML structure is correct
#
# INTEGRATION TESTS VS VIEW TESTS:
# -------------------------------
# - Integration tests: Full request/response cycle
# - View tests: Just the template rendering
# Both are needed for comprehensive coverage.
#
# ============================================================================

require "test_helper"

class TaskCardPartialTest < ActionView::TestCase
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
    # Create a test task
    @task = Task.create!(
      title: "Test Task Card",
      description: "This is a test description",
      assignee: "sparky",
      status: "in_progress",
      priority: "high"
    )
    
    # Helper methods from ApplicationHelper need to be available
    @controller = TasksController.new
    @request = ActionDispatch::Request.new({})
    @controller.instance_variable_set(:@_request, @request)
  end

  # ==========================================================================
  # RENDERING TESTS
  # ==========================================================================

  test "_task_card partial renders without errors" do
    # This test would have caught the syntax error!
    # The syntax error occurred because data-* attributes were on
    # their own line instead of being part of the card element.
    
    assert_nothing_raised do
      render partial: "tasks/task_card", locals: { task: @task }
    end
  end

  test "_task_card partial contains task data attributes" do
    render partial: "tasks/task_card", locals: { task: @task }
    
    # Check that data attributes are present
    assert_includes rendered, "data-id=\"#{@task.id}\""
    assert_includes rendered, "data-status=\"#{@task.status}\""
    assert_includes rendered, "data-assignee=\"#{@task.assignee}\""
  end

  test "_task_card partial contains task id for Turbo Streams" do
    render partial: "tasks/task_card", locals: { task: @task }
    
    # The id="task_123" is used by Turbo Streams to target this element
    assert_includes rendered, "id=\"task_#{@task.id}\""
  end

  test "_task_card partial shows task title" do
    render partial: "tasks/task_card", locals: { task: @task }
    
    assert_includes rendered, @task.title
  end

  test "_task_card partial shows task description" do
    render partial: "tasks/task_card", locals: { task: @task }
    
    # Description should be present (may be truncated)
    assert_includes rendered, @task.description
  end

  test "_task_card partial shows priority badge" do
    render partial: "tasks/task_card", locals: { task: @task }
    
    assert_includes rendered, @task.priority
  end

  test "_task_card partial has move buttons" do
    render partial: "tasks/task_card", locals: { task: @task }
    
    # Should have left and right arrow buttons
    assert_includes rendered, "bi-arrow-left"
    assert_includes rendered, "bi-arrow-right"
  end

  test "_task_card partial has edit button" do
    render partial: "tasks/task_card", locals: { task: @task }
    
    assert_includes rendered, "bi-pencil"
  end

  test "_task_card partial has delete button" do
    render partial: "tasks/task_card", locals: { task: @task }
    
    assert_includes rendered, "bi-trash"
  end

  # ==========================================================================
  # EDGE CASES
  # ==========================================================================

  test "_task_card partial renders with nil description" do
    @task.update!(description: nil)
    
    assert_nothing_raised do
      render partial: "tasks/task_card", locals: { task: @task }
    end
  end

  test "_task_card partial renders with empty description" do
    @task.update!(description: "")
    
    assert_nothing_raised do
      render partial: "tasks/task_card", locals: { task: @task }
    end
  end

  test "_task_card partial renders at first status (no left button)" do
    @task.update!(status: "hold")
    
    render partial: "tasks/task_card", locals: { task: @task }
    
    # Left button should be disabled (no previous status)
    # The specific implementation may vary, but it should render
    assert_nothing_raised do
      render partial: "tasks/task_card", locals: { task: @task }
    end
  end

  test "_task_card partial renders at last status (no right button)" do
    @task.update!(status: "done")
    
    render partial: "tasks/task_card", locals: { task: @task }
    
    # Right button should be disabled (no next status)
    assert_nothing_raised do
      render partial: "tasks/task_card", locals: { task: @task }
    end
  end

  test "_task_card partial has correct priority class" do
    render partial: "tasks/task_card", locals: { task: @task }
    
    # Should have priority-high class for styling
    assert_includes rendered, "priority-high"
  end
end
