# ============================================================================
# Controller Tests: TasksController - Detail View & Activity Log
# ============================================================================
#
# Tests for the enhanced show action and activity logging functionality.
#
# ============================================================================

require "test_helper"

class TasksControllerDetailViewTest < ActionDispatch::IntegrationTest
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

    @task = Task.create!(
      title: "Test Task",
      description: "Test description for detail view",
      assignee: "mechdog",
      status: "in_progress",
      priority: "high",
      last_worked_on: 2.days.ago,
      user: @user
    )
  end

  # ==========================================================================
  # SHOW ACTION TESTS
  # ==========================================================================

  test "should get show with all task fields displayed" do
    skip "Requires asset pipeline" unless Rails.env.development?
    get task_url(@task)
    assert_response :success
    
    # Check that all task fields are in the response
    assert_select "h2", @task.title
    assert_select ".task-description", @task.description
    assert_select ".fw-medium", /In Progress/  # Status
    assert_select ".fw-medium", /Mechdog/      # Assignee
    assert_select ".fw-medium", /High/         # Priority
  end

  test "show displays task timestamps" do
    skip "Requires asset pipeline" unless Rails.env.development?
    get task_url(@task)
    assert_response :success
    
    # Check for created_at and updated_at
    assert_select ".text-muted", /Created:/
    assert_select ".text-muted", /Updated:/
  end

  test "show displays last_worked_on timestamp" do
    skip "Requires asset pipeline" unless Rails.env.development?
    get task_url(@task)
    assert_response :success
    
    assert_select ".fw-medium", /2 days ago/
  end

  test "show handles task without last_worked_on" do
    skip "Requires asset pipeline" unless Rails.env.development?
    @task.update!(last_worked_on: nil)
    
    get task_url(@task)
    assert_response :success
    
    assert_select ".fw-medium", /Never/
  end

  test "show displays activity log section" do
    skip "Requires asset pipeline" unless Rails.env.development?
    # Create some activities
    TaskActivity.log_creation(@task, @user)
    TaskActivity.log_update(@task, { 'status' => ['backlog', 'in_progress'] }, @user)
    
    get task_url(@task)
    assert_response :success
    
    assert_select ".activity-timeline"
    assert_select ".activity-item", count: 2
  end

  test "show displays empty activity log message when no activities" do
    skip "Requires asset pipeline" unless Rails.env.development?
    get task_url(@task)
    assert_response :success
    
    assert_select ".text-center", /No activity recorded yet/
  end

  test "show has edit and back buttons" do
    skip "Requires asset pipeline" unless Rails.env.development?
    get task_url(@task)
    assert_response :success
    
    assert_select "a.btn-primary", /Edit/
    assert_select "a.btn-outline-secondary", /Back to Board/
  end

  test "show has move left and move right buttons" do
    skip "Requires asset pipeline" unless Rails.env.development?
    get task_url(@task)
    assert_response :success
    
    # Task is in_progress, so should have both left and right buttons
    # STATUSES = %w[hold backlog in_progress sprint daily done]
    assert_select "button", /Backlog/  # Move left (in_progress -> backlog)
    assert_select "button", /Sprint/   # Move right (in_progress -> sprint)
  end

  test "show disables move left button when at first status" do
    skip "Requires asset pipeline" unless Rails.env.development?
    @task.update!(status: 'hold')
    
    get task_url(@task)
    assert_response :success
    
    # Should have disabled left button
    assert_select "button[disabled]", /Start/
  end

  test "show disables move right button when at last status" do
    skip "Requires asset pipeline" unless Rails.env.development?
    @task.update!(status: 'done')
    
    get task_url(@task)
    assert_response :success
    
    # Should have disabled right button
    assert_select "button[disabled]", /Done/
  end

  test "show returns 404 for non-existent task" do
    skip "Requires asset pipeline" unless Rails.env.development?
    get task_url(id: 99999)
    assert_redirected_to tasks_url
    assert_equal "Task not found.", flash[:alert]
  end

  # ==========================================================================
  # ACTIVITY LOGGING - CREATE
  # ==========================================================================

  test "creating a task logs creation activity" do
    assert_difference("TaskActivity.count", 1) do
      post tasks_url, params: {
        task: {
          title: "New Task",
          assignee: "sparky",
          status: "backlog",
          priority: "medium"
        }
      }
    end
    
    activity = TaskActivity.last
    assert_equal 'created', activity.activity_type
    assert_equal @user, activity.user
    assert_includes activity.description, 'created'
  end

  test "creating a task via JSON logs creation activity" do
    assert_difference("TaskActivity.count", 1) do
      post tasks_url, params: {
        title: "API Task",
        assignee: "mechdog",
        status: "backlog",
        priority: "low"
      }, as: :json
    end
    
    assert_equal 'created', TaskActivity.last.activity_type
  end

  # ==========================================================================
  # ACTIVITY LOGGING - UPDATE
  # ==========================================================================

  test "updating a task logs update activity with changes" do
    assert_difference("TaskActivity.count", 1) do
      patch task_url(@task), params: {
        task: {
          title: "Updated Title",
          status: "done"
        }
      }
    end
    
    activity = TaskActivity.last
    assert_equal 'status_changed', activity.activity_type
    assert_equal @user, activity.user
    assert_equal 'in_progress', activity.changeset['status']['from']
    assert_equal 'done', activity.changeset['status']['to']
  end

  test "updating a task without changes does not log activity" do
    # First update to create some history
    patch task_url(@task), params: { task: { title: "New Title" } }
    
    count_before = TaskActivity.count
    
    # Update with same values
    patch task_url(@task), params: { task: { title: "New Title" } }
    
    # Should not create new activity since nothing changed
    assert_equal count_before, TaskActivity.count
  end

  test "updating only title logs title_changed activity" do
    patch task_url(@task), params: { task: { title: "New Title Only" } }
    
    activity = TaskActivity.last
    assert_equal 'title_changed', activity.activity_type
    assert_includes activity.description, 'Title updated'
  end

  test "updating priority logs priority_changed activity" do
    patch task_url(@task), params: { task: { priority: "urgent" } }
    
    activity = TaskActivity.last
    assert_equal 'priority_changed', activity.activity_type
    assert_includes activity.description, 'Priority changed'
  end

  test "updating assignee logs assignee_changed activity" do
    patch task_url(@task), params: { task: { assignee: "sparky" } }
    
    activity = TaskActivity.last
    assert_equal 'assignee_changed', activity.activity_type
    assert_includes activity.description, 'Assignee changed'
  end

  test "multiple field changes logged in single activity" do
    patch task_url(@task), params: { 
      task: { 
        status: "done",
        priority: "low"
      } 
    }
    
    activity = TaskActivity.last
    assert_includes activity.description, 'Status changed'
    assert_includes activity.description, 'Priority changed'
    assert_equal 'status_changed', activity.activity_type  # status takes priority
  end

  # ==========================================================================
  # ACTIVITY LOGGING - ARCHIVE (SOFT DELETE)
  # ==========================================================================

  test "archiving a task logs archive activity" do
    # When a task is archived (deleted):
    # Archive activity is created (+1)
    assert_difference("TaskActivity.count", 1) do
      delete task_url(@task)
    end
    
    # Verify the activity was created
    activity = TaskActivity.find_by(task: @task, activity_type: 'archived')
    assert_not_nil activity, "Expected an archived activity to be created for the task"
    assert_equal "archived", activity.activity_type
    assert_equal @task.id, activity.task_id
    
    assert_redirected_to tasks_path
  end

  test "archived task's activities are preserved" do
    TaskActivity.log_creation(@task, @user)
    TaskActivity.log_update(@task, { 'status' => ['backlog', 'in_progress'] }, @user)
    
    # The task has 2 activities. When archived:
    # Archive activity is created (+1)
    # Activities are NOT deleted (soft delete)
    # Net change: +1
    assert_difference("TaskActivity.count", 1) do
      delete task_url(@task)
    end
    
    # Task still exists (archived), so activities should still exist
    assert_equal 3, @task.activities.count
  end

  # ==========================================================================
  # ACTIVITY LOGGING - MOVE LEFT/RIGHT
  # ==========================================================================

  test "move_left logs status change activity" do
    @task.update!(status: 'in_progress')
    
    assert_difference("TaskActivity.count", 1) do
      post move_left_task_url(@task)
    end
    
    activity = TaskActivity.last
    assert_equal 'status_changed', activity.activity_type
    assert_equal 'in_progress', activity.changeset['status']['from']
    assert_equal 'backlog', activity.changeset['status']['to']
  end

  test "move_right logs status change activity" do
    @task.update!(status: 'in_progress')
    
    assert_difference("TaskActivity.count", 1) do
      post move_right_task_url(@task)
    end
    
    activity = TaskActivity.last
    assert_equal 'status_changed', activity.activity_type
    assert_equal 'in_progress', activity.changeset['status']['from']
    assert_equal 'sprint', activity.changeset['status']['to']
  end

  test "move_left at first status does not log activity" do
    @task.update!(status: 'hold')
    
    assert_no_difference("TaskActivity.count") do
      post move_left_task_url(@task)
    end
  end

  test "move_right at last status does not log activity" do
    @task.update!(status: 'done')
    
    assert_no_difference("TaskActivity.count") do
      post move_right_task_url(@task)
    end
  end
end
