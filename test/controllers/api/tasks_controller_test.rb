# ============================================================================
# API Controller Tests: Api::TasksController
# ============================================================================
#
# LEARNING NOTES:
#
# These test the JSON API endpoints.
# Important for ensuring API contracts are maintained.
#
# KEY CONCEPTS:
# - as: :json - sends request with JSON headers
# - JSON.parse(@response.body) - parse JSON response
# - assert_response :created - check specific HTTP status
#
# ============================================================================

require "test_helper"

class Api::TasksControllerTest < ActionDispatch::IntegrationTest
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
    @task = Task.create!(
      title: "API Test Task",
      description: "Test via API",
      assignee: "sparky",
      status: "backlog",
      priority: "medium"
    )
  end

  # ==========================================================================
  # INDEX TESTS
  # ==========================================================================

  test "GET /api/tasks returns JSON" do
    get api_tasks_url, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    assert_kind_of Array, json
    assert json.any? { |t| t["title"] == "API Test Task" }
  end

  test "GET /api/tasks filters by assignee" do
    Task.create!(title: "MechDog Task", assignee: "mechdog", status: "backlog", priority: "low")
    
    get api_tasks_url(assignee: "sparky"), as: :json
    
    json = JSON.parse(@response.body)
    assert json.all? { |t| t["assignee"] == "sparky" }
  end

  test "GET /api/tasks filters by status" do
    Task.create!(title: "Done Task", assignee: "mechdog", status: "done", priority: "low")
    
    get api_tasks_url(status: "done"), as: :json
    
    json = JSON.parse(@response.body)
    assert json.all? { |t| t["status"] == "done" }
  end

  # ==========================================================================
  # SHOW TESTS
  # ==========================================================================

  test "GET /api/tasks/:id returns single task" do
    get api_task_url(@task), as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    assert_equal @task.title, json["title"]
    assert_equal @task.assignee, json["assignee"]
  end

  test "GET /api/tasks/:id returns 404 for missing task" do
    get api_task_url(id: 99999), as: :json
    
    assert_response :not_found
    
    json = JSON.parse(@response.body)
    assert_equal "Task not found", json["error"]
  end

  # ==========================================================================
  # CREATE TESTS
  # ==========================================================================

  test "POST /api/tasks creates task" do
    assert_difference("Task.count", 1) do
      post api_tasks_url, params: {
        title: "New API Task",
        assignee: "mechdog",
        priority: "high"
      }, as: :json
    end
    
    assert_response :created
    
    json = JSON.parse(@response.body)
    assert_equal "New API Task", json["title"]
    assert_equal "mechdog", json["assignee"]
    assert_equal "backlog", json["status"]  # Default
    assert_equal "high", json["priority"]
  end

  test "POST /api/tasks returns errors for invalid data" do
    assert_no_difference("Task.count") do
      post api_tasks_url, params: {
        title: "",  # Invalid - required
        assignee: "mechdog"
      }, as: :json
    end
    
    assert_response :unprocessable_entity
    
    json = JSON.parse(@response.body)
    assert json["errors"].any? { |e| e.include?("Title") }
  end

  test "POST /api/tasks rejects invalid assignee" do
    post api_tasks_url, params: {
      title: "Test",
      assignee: "unknown_user"
    }, as: :json
    
    assert_response :unprocessable_entity
  end

  # ==========================================================================
  # UPDATE TESTS
  # ==========================================================================

  test "PATCH /api/tasks/:id updates task" do
    patch api_task_url(@task), params: {
      title: "Updated via API",
      status: "in_progress"
    }, as: :json
    
    assert_response :success
    
    json = JSON.parse(@response.body)
    assert_equal "Updated via API", json["title"]
    assert_equal "in_progress", json["status"]
    
    @task.reload
    assert_equal "Updated via API", @task.title
  end

  test "PATCH /api/tasks/:id returns errors for invalid data" do
    patch api_task_url(@task), params: {
      status: "invalid_status"
    }, as: :json
    
    assert_response :unprocessable_entity
  end

  test "PATCH /api/tasks/:id returns 404 for missing task" do
    patch api_task_url(id: 99999), params: { title: "Test" }, as: :json
    
    assert_response :not_found
  end

  # ==========================================================================
  # DESTROY TESTS
  # ==========================================================================

  test "DELETE /api/tasks/:id removes task" do
    assert_difference("Task.count", -1) do
      delete api_task_url(@task), as: :json
    end
    
    assert_response :no_content
  end

  test "DELETE /api/tasks/:id returns 404 for missing task" do
    delete api_task_url(id: 99999), as: :json
    
    assert_response :not_found
  end

  # ==========================================================================
  # INTEGRATION TESTS
  # ==========================================================================

  test "full CRUD lifecycle via API" do
    # CREATE
    post api_tasks_url, params: {
      title: "Lifecycle Task",
      assignee: "sparky"
    }, as: :json
    assert_response :created
    task_id = JSON.parse(@response.body)["id"]
    
    # READ
    get api_task_url(id: task_id), as: :json
    assert_response :success
    assert_equal "Lifecycle Task", JSON.parse(@response.body)["title"]
    
    # UPDATE
    patch api_task_url(id: task_id), params: {
      status: "done"
    }, as: :json
    assert_response :success
    assert_equal "done", JSON.parse(@response.body)["status"]
    
    # DELETE
    delete api_task_url(id: task_id), as: :json
    assert_response :no_content
    
    # VERIFY DELETED
    get api_task_url(id: task_id), as: :json
    assert_response :not_found
  end

  # ==========================================================================
  # LAST_WORKED_ON API TESTS
  # ==========================================================================

  test "GET /api/tasks/:id includes last_worked_on in response" do
    freeze_time = Time.current
    @task.update!(last_worked_on: freeze_time)
    
    get api_task_url(@task), as: :json
    
    assert_response :success
    json = JSON.parse(@response.body)
    assert json.key?("last_worked_on")
    assert_equal freeze_time.iso8601(3), json["last_worked_on"]
  end

  test "GET /api/tasks/:id returns null last_worked_on when not set" do
    @task.update!(last_worked_on: nil)
    
    get api_task_url(@task), as: :json
    
    assert_response :success
    json = JSON.parse(@response.body)
    assert_nil json["last_worked_on"]
  end

  test "GET /api/tasks includes last_worked_on in each task" do
    @task.update!(last_worked_on: 2.days.ago)
    
    get api_tasks_url, as: :json
    
    assert_response :success
    json = JSON.parse(@response.body)
    task = json.find { |t| t["id"] == @task.id }
    assert task.key?("last_worked_on")
    assert_not_nil task["last_worked_on"]
  end

  test "POST /api/tasks/:id/touch_last_worked updates last_worked_on" do
    @task.update!(last_worked_on: nil)
    freeze_time = Time.current
    
    travel_to freeze_time do
      post touch_last_worked_api_task_url(@task), as: :json
    end
    
    assert_response :success
    @task.reload
    assert_equal freeze_time.to_i, @task.last_worked_on.to_i
  end

  test "POST /api/tasks/:id/touch_last_worked returns success response" do
    post touch_last_worked_api_task_url(@task), as: :json
    
    assert_response :success
    json = JSON.parse(@response.body)
    assert json["success"]
    assert json["last_worked_on"]
    assert_match(/marked as worked on/, json["message"])
  end

  test "POST /api/tasks/:id/touch_last_worked returns 404 for missing task" do
    post touch_last_worked_api_task_url(id: 99999), as: :json
    
    assert_response :not_found
  end

  test "PATCH /api/tasks/:id updates last_worked_on when status changes" do
    @task.update!(status: "backlog", last_worked_on: nil)
    freeze_time = Time.current
    
    travel_to freeze_time do
      patch api_task_url(@task), params: { status: "in_progress" }, as: :json
    end
    
    assert_response :success
    @task.reload
    assert_equal freeze_time.to_i, @task.last_worked_on.to_i
  end

  test "PATCH /api/tasks/:id updates last_worked_on when assignee changes" do
    @task.update!(assignee: "mechdog", last_worked_on: nil)
    freeze_time = Time.current
    
    travel_to freeze_time do
      patch api_task_url(@task), params: { assignee: "sparky" }, as: :json
    end
    
    assert_response :success
    @task.reload
    assert_equal freeze_time.to_i, @task.last_worked_on.to_i
  end

  test "PATCH /api/tasks/:id does not update last_worked_on for title changes" do
    original_time = 1.day.ago
    @task.update!(last_worked_on: original_time)
    
    patch api_task_url(@task), params: { title: "Updated Title" }, as: :json
    
    assert_response :success
    @task.reload
    assert_equal original_time.to_i, @task.last_worked_on.to_i
  end

  test "PATCH /api/tasks/:id can directly set last_worked_on" do
    custom_time = 3.days.ago.iso8601(3)
    
    patch api_task_url(@task), params: { last_worked_on: custom_time }, as: :json
    
    assert_response :success
    @task.reload
    assert_equal custom_time, @task.last_worked_on.iso8601(3)
  end

  test "POST /api/tasks can set last_worked_on on create" do
    custom_time = 2.days.ago
    
    post api_tasks_url, params: {
      title: "Task with Last Worked",
      assignee: "sparky",
      last_worked_on: custom_time
    }, as: :json
    
    assert_response :created
    json = JSON.parse(@response.body)
    assert_equal custom_time.iso8601(3), json["last_worked_on"]
  end
end
