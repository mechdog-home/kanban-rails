# ============================================================================
# Controller Tests: TasksController - Archiving/Soft Deletion
# ============================================================================
#
# LEARNING NOTES:
#
# These tests cover the archived tasks controller actions:
# - destroy (now archives instead of deleting)
# - archived (lists archived tasks)
# - restore (unarchives a task)
#
# ============================================================================

require "test_helper"

class TasksControllerArchivingTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
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

    # Create a test task before each test
    @task = Task.create!(
      title: "Test Task",
      description: "Test description",
      assignee: "mechdog",
      status: "backlog",
      priority: "medium",
      user: @user
    )
  end

  # ==========================================================================
  # DESTROY (ARCHIVE) TESTS
  # ==========================================================================

  test "destroy archives task instead of deleting" do
    assert_no_difference("Task.unscoped.count") do
      delete task_url(@task)
    end
    
    @task.reload
    assert_equal true, @task.archived?
  end
  
  test "destroy redirects to tasks path with success message" do
    delete task_url(@task)
    
    assert_redirected_to tasks_path
    assert_equal "Task was successfully archived.", flash[:notice]
  end
  
  test "destroy creates archive activity log" do
    assert_difference("TaskActivity.count", 1) do
      delete task_url(@task)
    end
    
    # Find the activity for this specific task
    activity = TaskActivity.find_by(task: @task, activity_type: 'archived')
    assert_not_nil activity, "Expected an archived activity to be created for the task"
    assert_equal "archived", activity.activity_type
    assert_equal @task.id, activity.task_id
  end
  
  test "destroy via json returns no_content" do
    delete task_url(@task), as: :json
    
    assert_response :no_content
    @task.reload
    assert_equal true, @task.archived?
  end
  
  test "archived task is excluded from index" do
    delete task_url(@task)
    
    get tasks_url
    assert_response :success
    assert_no_match(/Test Task/, @response.body)
  end

  # ==========================================================================
  # ARCHIVED INDEX TESTS
  # ==========================================================================

  test "archived action shows archived tasks" do
    @task.archive!
    
    get archived_tasks_url
    assert_response :success
    assert_match(/Test Task/, @response.body)
  end
  
  test "archived action excludes active tasks" do
    # @task is still active
    get archived_tasks_url
    assert_response :success
    assert_no_match(/Test Task/, @response.body)
  end
  
  test "archived action shows empty state when no archived tasks" do
    get archived_tasks_url
    assert_response :success
    assert_match(/No Archived Tasks/, @response.body)
  end
  
  test "archived action shows archive count in header" do
    @task.archive!
    
    get archived_tasks_url
    assert_response :success
    assert_match(/Archived Tasks.*1/, @response.body)
  end
  
  test "archived action filters by assignee" do
    @task.archive!
    sparky_task = Task.create!(
      title: "Sparky Task",
      assignee: "sparky",
      status: "backlog",
      priority: "medium"
    )
    sparky_task.archive!
    
    get archived_tasks_url(assignee: "mechdog")
    assert_response :success
    assert_match(/Test Task/, @response.body)
    assert_no_match(/Sparky Task/, @response.body)
  end

  # ==========================================================================
  # RESTORE TESTS
  # ==========================================================================

  test "restore unarchives a task" do
    @task.archive!
    assert_equal true, @task.reload.archived?
    
    post restore_task_url(@task)
    
    assert_equal false, @task.reload.archived?
  end
  
  test "restore redirects to archived tasks path" do
    @task.archive!
    
    post restore_task_url(@task)
    
    assert_redirected_to archived_tasks_path
    assert_equal "Task was successfully restored.", flash[:notice]
  end
  
  test "restore creates restore activity log" do
    @task.archive!
    
    assert_difference("TaskActivity.count", 1) do
      post restore_task_url(@task)
    end
    
    activity = TaskActivity.last
    assert_equal "restored", activity.activity_type
    assert_equal @task, activity.task
  end
  
  test "restore via json returns task" do
    @task.archive!
    
    post restore_task_url(@task), as: :json
    
    assert_response :success
    json = JSON.parse(@response.body)
    assert_equal @task.id, json["id"]
    assert_equal false, json["archived"]
  end
  
  test "restored task appears in main board" do
    @task.archive!
    post restore_task_url(@task)
    
    get tasks_url
    assert_response :success
    assert_match(/Test Task/, @response.body)
  end
  
  test "restored task no longer appears in archived list" do
    @task.archive!
    post restore_task_url(@task)
    
    get archived_tasks_url
    assert_response :success
    assert_no_match(/Test Task/, @response.body)
  end
  
  test "restore returns 404 for non-existent task" do
    post restore_task_url(id: 99999)
    
    assert_redirected_to archived_tasks_path
    assert_equal "Task not found.", flash[:alert]
  end

  # ==========================================================================
  # NAVIGATION LINK TESTS
  # ==========================================================================

  test "main board shows archived link with count" do
    get tasks_url
    assert_response :success
    assert_match(/Archived/, @response.body)
  end
  
  test "archived page shows back to board link" do
    get archived_tasks_url
    assert_response :success
    assert_match(/Back to Board/, @response.body)
  end
end
