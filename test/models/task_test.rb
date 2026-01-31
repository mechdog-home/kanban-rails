# ============================================================================
# Model Tests: Task
# ============================================================================
#
# LEARNING NOTES:
#
# These are unit tests for the Task model.
# Rails uses Minitest by default (similar to RSpec but simpler).
#
# KEY CONCEPTS:
# - test "description" do ... end - defines a test case
# - assert/assert_equal/assert_not - make assertions
# - setup - runs before each test
# - fixtures - sample data loaded automatically
#
# COMPARISON TO RSPEC:
# - RSpec: it "should do something" do ... end
# - Minitest: test "should do something" do ... end
# - RSpec: expect(x).to eq(y)
# - Minitest: assert_equal y, x
#
# RUN TESTS:
#   rails test                          # All tests
#   rails test test/models/task_test.rb # Just this file
#   rails test -n "test_name"           # Specific test
#
# ============================================================================

require "test_helper"

class TaskTest < ActiveSupport::TestCase
  # ==========================================================================
  # SETUP
  # ==========================================================================
  
  # This runs before each test
  # Creates a valid task we can use or modify
  setup do
    @valid_attributes = {
      title: "Test Task",
      description: "A test task description",
      assignee: "mechdog",
      status: "backlog",
      priority: "medium"
    }
  end

  # ==========================================================================
  # VALIDATION TESTS
  # ==========================================================================
  
  test "valid task saves successfully" do
    task = Task.new(@valid_attributes)
    assert task.valid?, "Task should be valid with all required attributes"
    assert task.save, "Task should save successfully"
  end

  test "requires title" do
    task = Task.new(@valid_attributes.except(:title))
    assert_not task.valid?, "Task should be invalid without title"
    assert_includes task.errors[:title], "can't be blank"
  end

  test "requires assignee" do
    task = Task.new(@valid_attributes.except(:assignee))
    assert_not task.valid?, "Task should be invalid without assignee"
  end

  test "assignee must be valid option" do
    task = Task.new(@valid_attributes.merge(assignee: "invalid_user"))
    assert_not task.valid?, "Task should be invalid with unknown assignee"
    assert_includes task.errors[:assignee], "is not included in the list"
  end

  test "accepts valid assignees" do
    Task::ASSIGNEES.each do |assignee|
      task = Task.new(@valid_attributes.merge(assignee: assignee))
      assert task.valid?, "Task should accept assignee: #{assignee}"
    end
  end

  test "status must be valid option" do
    task = Task.new(@valid_attributes.merge(status: "invalid_status"))
    assert_not task.valid?, "Task should be invalid with unknown status"
  end

  test "accepts valid statuses" do
    Task::STATUSES.each do |status|
      task = Task.new(@valid_attributes.merge(status: status))
      assert task.valid?, "Task should accept status: #{status}"
    end
  end

  test "priority must be valid option" do
    task = Task.new(@valid_attributes.merge(priority: "invalid_priority"))
    assert_not task.valid?, "Task should be invalid with unknown priority"
  end

  test "accepts valid priorities" do
    Task::PRIORITIES.each do |priority|
      task = Task.new(@valid_attributes.merge(priority: priority))
      assert task.valid?, "Task should accept priority: #{priority}"
    end
  end

  test "description is optional" do
    task = Task.new(@valid_attributes.except(:description))
    assert task.valid?, "Task should be valid without description"
  end

  # ==========================================================================
  # DEFAULT VALUE TESTS
  # ==========================================================================

  test "status defaults to backlog" do
    task = Task.create!(@valid_attributes.except(:status))
    assert_equal "backlog", task.status
  end

  test "priority defaults to medium" do
    task = Task.create!(@valid_attributes.except(:priority))
    assert_equal "medium", task.priority
  end

  # ==========================================================================
  # SCOPE TESTS
  # ==========================================================================

  test "for_assignee scope filters by assignee" do
    Task.create!(@valid_attributes.merge(title: "Task 1", assignee: "mechdog"))
    Task.create!(@valid_attributes.merge(title: "Task 2", assignee: "sparky"))
    Task.create!(@valid_attributes.merge(title: "Task 3", assignee: "mechdog"))
    
    mechdog_tasks = Task.for_assignee("mechdog")
    assert_equal 2, mechdog_tasks.count
    assert mechdog_tasks.all? { |t| t.assignee == "mechdog" }
  end

  test "with_status scope filters by status" do
    Task.create!(@valid_attributes.merge(title: "Task 1", status: "backlog"))
    Task.create!(@valid_attributes.merge(title: "Task 2", status: "in_progress"))
    Task.create!(@valid_attributes.merge(title: "Task 3", status: "backlog"))
    
    backlog_tasks = Task.with_status("backlog")
    assert_equal 2, backlog_tasks.count
    assert backlog_tasks.all? { |t| t.status == "backlog" }
  end

  test "backlog scope returns only backlog tasks" do
    Task.create!(@valid_attributes.merge(title: "Task 1", status: "backlog"))
    Task.create!(@valid_attributes.merge(title: "Task 2", status: "done"))
    
    assert_equal 1, Task.backlog.count
    assert_equal "backlog", Task.backlog.first.status
  end

  test "in_progress scope returns only in_progress tasks" do
    Task.create!(@valid_attributes.merge(title: "Task 1", status: "in_progress"))
    Task.create!(@valid_attributes.merge(title: "Task 2", status: "backlog"))
    
    assert_equal 1, Task.in_progress.count
    assert_equal "in_progress", Task.in_progress.first.status
  end

  test "done scope returns only done tasks" do
    Task.create!(@valid_attributes.merge(title: "Task 1", status: "done"))
    Task.create!(@valid_attributes.merge(title: "Task 2", status: "backlog"))
    
    assert_equal 1, Task.done.count
    assert_equal "done", Task.done.first.status
  end

  test "recent scope orders by updated_at descending" do
    old_task = Task.create!(@valid_attributes.merge(title: "Old"))
    old_task.update!(updated_at: 1.day.ago)
    new_task = Task.create!(@valid_attributes.merge(title: "New"))
    
    tasks = Task.recent
    assert_equal new_task, tasks.first
    assert_equal old_task, tasks.last
  end

  test "scopes are chainable" do
    Task.create!(@valid_attributes.merge(title: "T1", assignee: "mechdog", status: "backlog"))
    Task.create!(@valid_attributes.merge(title: "T2", assignee: "mechdog", status: "done"))
    Task.create!(@valid_attributes.merge(title: "T3", assignee: "sparky", status: "backlog"))
    
    result = Task.for_assignee("mechdog").backlog
    assert_equal 1, result.count
    assert_equal "T1", result.first.title
  end

  # ==========================================================================
  # INSTANCE METHOD TESTS
  # ==========================================================================

  test "done? returns true for done tasks" do
    task = Task.new(@valid_attributes.merge(status: "done"))
    assert task.done?
  end

  test "done? returns false for non-done tasks" do
    task = Task.new(@valid_attributes.merge(status: "backlog"))
    assert_not task.done?
  end

  test "in_progress? returns true for in_progress tasks" do
    task = Task.new(@valid_attributes.merge(status: "in_progress"))
    assert task.in_progress?
  end

  test "urgent? returns true for urgent tasks" do
    task = Task.new(@valid_attributes.merge(priority: "urgent"))
    assert task.urgent?
  end

  test "urgent? returns false for non-urgent tasks" do
    task = Task.new(@valid_attributes.merge(priority: "low"))
    assert_not task.urgent?
  end

  test "advance_status! moves task to next status" do
    task = Task.create!(@valid_attributes.merge(status: "backlog"))
    
    task.advance_status!
    assert_equal "in_progress", task.status
    
    task.advance_status!
    assert_equal "sprint", task.status
    
    task.advance_status!
    assert_equal "daily", task.status
    
    task.advance_status!
    assert_equal "done", task.status
  end

  test "advance_status! does nothing when already done" do
    task = Task.create!(@valid_attributes.merge(status: "done"))
    task.advance_status!
    assert_equal "done", task.status
  end

  # ==========================================================================
  # CLASS METHOD TESTS
  # ==========================================================================

  test "grouped_by_status returns hash of tasks by status" do
    Task.create!(@valid_attributes.merge(title: "T1", status: "backlog"))
    Task.create!(@valid_attributes.merge(title: "T2", status: "done"))
    Task.create!(@valid_attributes.merge(title: "T3", status: "backlog"))
    
    grouped = Task.grouped_by_status
    
    assert_kind_of Hash, grouped
    assert_equal 2, grouped["backlog"].count
    assert_equal 1, grouped["done"].count
  end

  test "grouped_by_assignee returns hash of tasks by assignee" do
    Task.create!(@valid_attributes.merge(title: "T1", assignee: "mechdog"))
    Task.create!(@valid_attributes.merge(title: "T2", assignee: "sparky"))
    
    grouped = Task.grouped_by_assignee
    
    assert_kind_of Hash, grouped
    assert_equal 1, grouped["mechdog"].count
    assert_equal 1, grouped["sparky"].count
  end
end
