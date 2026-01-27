# ============================================================================
# Controller Tests: TasksController
# ============================================================================
#
# LEARNING NOTES:
#
# These are functional tests for the TasksController.
# They test HTTP requests and responses.
#
# KEY CONCEPTS:
# - get/post/patch/delete - simulate HTTP requests
# - assert_response - check HTTP status codes
# - assert_redirected_to - check redirects
# - @response.body - access response content
#
# COMPARISON TO EXPRESS TESTING:
# - Express: supertest library with request(app).get('/tasks')
# - Rails: get tasks_url (built-in)
#
# ============================================================================

require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
    # Create a test user and sign in before each test
    # Without this, Devise redirects all requests to the login page (302)
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
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
      priority: "medium"
    )
  end

  # ==========================================================================
  # INDEX TESTS
  # ==========================================================================

  test "should get index" do
    # Skip in CI - requires full asset pipeline
    skip "Requires asset pipeline" if ENV["CI"]
    get tasks_url
    assert_response :success
  end

  test "index shows all tasks" do
    skip "Requires asset pipeline" if ENV["CI"]
    Task.create!(title: "Task 2", assignee: "sparky", status: "backlog", priority: "low")
    
    get tasks_url
    assert_response :success
    # In a real test, you'd check the response body contains the tasks
  end

  # ==========================================================================
  # SHOW TESTS
  # ==========================================================================

  test "should get show" do
    skip "Requires asset pipeline" if ENV["CI"]
    get task_url(@task)
    assert_response :success
  end

  # ==========================================================================
  # NEW TESTS
  # ==========================================================================

  test "should get new" do
    skip "Requires asset pipeline" if ENV["CI"]
    get new_task_url
    assert_response :success
  end

  # ==========================================================================
  # CREATE TESTS
  # ==========================================================================

  test "should create task with valid params" do
    assert_difference("Task.count", 1) do
      post tasks_url, params: {
        task: {
          title: "New Task",
          assignee: "sparky",
          status: "backlog",
          priority: "high"
        }
      }
    end
    
    assert_redirected_to tasks_url
  end

  test "should not create task without title" do
    assert_no_difference("Task.count") do
      post tasks_url, params: {
        task: {
          title: "",
          assignee: "mechdog"
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  test "should not create task with invalid assignee" do
    assert_no_difference("Task.count") do
      post tasks_url, params: {
        task: {
          title: "Test",
          assignee: "invalid"
        }
      }
    end
    
    assert_response :unprocessable_entity
  end

  # ==========================================================================
  # EDIT TESTS
  # ==========================================================================

  test "should get edit" do
    skip "Requires asset pipeline" if ENV["CI"]
    get edit_task_url(@task)
    assert_response :success
  end

  # ==========================================================================
  # UPDATE TESTS
  # ==========================================================================

  test "should update task with valid params" do
    patch task_url(@task), params: {
      task: {
        title: "Updated Title",
        status: "in_progress"
      }
    }
    
    assert_redirected_to tasks_url
    @task.reload
    assert_equal "Updated Title", @task.title
    assert_equal "in_progress", @task.status
  end

  test "should not update task with invalid params" do
    patch task_url(@task), params: {
      task: {
        title: ""
      }
    }
    
    assert_response :unprocessable_entity
    @task.reload
    assert_equal "Test Task", @task.title  # Unchanged
  end

  # ==========================================================================
  # DESTROY TESTS
  # ==========================================================================

  test "should destroy task" do
    assert_difference("Task.count", -1) do
      delete task_url(@task)
    end
    
    assert_redirected_to tasks_url
  end

  test "destroyed task no longer exists" do
    delete task_url(@task)
    
    assert_raises(ActiveRecord::RecordNotFound) do
      Task.find(@task.id)
    end
  end
end
