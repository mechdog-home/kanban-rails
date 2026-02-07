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

  # ==========================================================================
  # LAST_WORKED_ON TESTS
  # ==========================================================================
  #
  # These tests cover the last_worked_on datetime field and related methods.
  # This field tracks when Sparky last worked on a task so MechDog can see
  # which tasks are dormant and need attention.
  #

  test "last_worked_on is nil by default" do
    task = Task.create!(@valid_attributes)
    assert_nil task.last_worked_on
  end

  test "touch_last_worked! updates last_worked_on to current time" do
    task = Task.create!(@valid_attributes)
    freeze_time = Time.current
    
    travel_to freeze_time do
      task.touch_last_worked!
    end
    
    task.reload
    assert_equal freeze_time.to_i, task.last_worked_on.to_i
  end

  test "touch_last_worked! bypasses validations and callbacks" do
    task = Task.create!(@valid_attributes)
    
    # This should work even if we make the task temporarily invalid
    # (since update_column bypasses validations)
    assert_nothing_raised do
      task.touch_last_worked!
    end
  end

  test "dormant? returns false when last_worked_on is nil" do
    task = Task.create!(@valid_attributes.merge(last_worked_on: nil))
    assert_not task.dormant?
  end

  test "dormant? returns false for recently worked tasks" do
    task = Task.create!(@valid_attributes.merge(last_worked_on: 1.day.ago))
    assert_not task.dormant?
  end

  test "dormant? returns true for tasks not worked on in 7 days" do
    task = Task.create!(@valid_attributes.merge(last_worked_on: 8.days.ago))
    assert task.dormant?
  end

  test "dormant? returns true for tasks exactly at 7 day boundary" do
    task = Task.create!(@valid_attributes.merge(last_worked_on: 7.days.ago - 1.minute))
    assert task.dormant?
  end

  test "time_since_work returns 'Never' when last_worked_on is nil" do
    task = Task.new(@valid_attributes.merge(last_worked_on: nil))
    assert_equal "Never", task.time_since_work
  end

  test "time_since_work returns human readable time" do
    task = Task.new(@valid_attributes.merge(last_worked_on: 2.hours.ago))
    assert_match(/2 hours ago/, task.time_since_work)
  end

  test "by_last_worked scope orders by last_worked_on descending" do
    old_task = Task.create!(@valid_attributes.merge(title: "Old", last_worked_on: 5.days.ago))
    new_task = Task.create!(@valid_attributes.merge(title: "New", last_worked_on: 1.day.ago))
    no_work_task = Task.create!(@valid_attributes.merge(title: "Never", last_worked_on: nil))
    
    tasks = Task.by_last_worked
    
    # Tasks with last_worked_on come first (newest to oldest)
    assert_equal new_task, tasks[0]
    assert_equal old_task, tasks[1]
    # Tasks with nil last_worked_on come last
    assert_equal no_work_task, tasks[2]
  end

  test "dormant scope returns tasks not worked on in 7 days" do
    dormant_task = Task.create!(@valid_attributes.merge(title: "Dormant", last_worked_on: 10.days.ago))
    recent_task = Task.create!(@valid_attributes.merge(title: "Recent", last_worked_on: 1.day.ago))
    never_task = Task.create!(@valid_attributes.merge(title: "Never", last_worked_on: nil))
    
    dormant_tasks = Task.dormant
    
    assert_includes dormant_tasks, dormant_task
    assert_includes dormant_tasks, never_task
    assert_not_includes dormant_tasks, recent_task
  end

  test "updating status updates last_worked_on automatically" do
    task = Task.create!(@valid_attributes.merge(status: "backlog", last_worked_on: nil))
    
    freeze_time = Time.current
    travel_to freeze_time do
      task.update!(status: "in_progress")
    end
    
    task.reload
    assert_equal freeze_time.to_i, task.last_worked_on.to_i
  end

  test "updating assignee updates last_worked_on automatically" do
    task = Task.create!(@valid_attributes.merge(assignee: "mechdog", last_worked_on: nil))
    
    freeze_time = Time.current
    travel_to freeze_time do
      task.update!(assignee: "sparky")
    end
    
    task.reload
    assert_equal freeze_time.to_i, task.last_worked_on.to_i
  end

  test "updating title does not update last_worked_on" do
    task = Task.create!(@valid_attributes.merge(title: "Original", last_worked_on: 1.day.ago))
    original_time = task.last_worked_on
    
    task.update!(title: "Updated")
    task.reload
    
    assert_equal original_time.to_i, task.last_worked_on.to_i
  end

  test "updating description does not update last_worked_on" do
    task = Task.create!(@valid_attributes.merge(last_worked_on: 1.day.ago))
    original_time = task.last_worked_on
    
    task.update!(description: "Updated description")
    task.reload
    
    assert_equal original_time.to_i, task.last_worked_on.to_i
  end

  test "updating priority does not update last_worked_on" do
    task = Task.create!(@valid_attributes.merge(priority: "low", last_worked_on: 1.day.ago))
    original_time = task.last_worked_on
    
    task.update!(priority: "high")
    task.reload
    
    assert_equal original_time.to_i, task.last_worked_on.to_i
  end

  test "advance_status! updates last_worked_on" do
    task = Task.create!(@valid_attributes.merge(status: "backlog", last_worked_on: nil))
    
    freeze_time = Time.current
    travel_to freeze_time do
      task.advance_status!
    end
    
    task.reload
    assert_equal freeze_time.to_i, task.last_worked_on.to_i
  end

  test "regress_status! updates last_worked_on" do
    task = Task.create!(@valid_attributes.merge(status: "in_progress", last_worked_on: nil))
    
    freeze_time = Time.current
    travel_to freeze_time do
      task.regress_status!
    end
    
    task.reload
    assert_equal freeze_time.to_i, task.last_worked_on.to_i
  end
end
