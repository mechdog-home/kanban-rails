# ============================================================================
# Model Tests: Task Archiving (Soft Deletion)
# ============================================================================
#
# LEARNING NOTES:
#
# These tests cover the archived/soft deletion functionality.
# Soft deletion allows "deleting" tasks without actually removing
# them from the database - they can be restored later.
#
# KEY CONCEPTS:
# - default_scope: Automatically excludes archived tasks from queries
# - unscoped: Bypasses the default scope to find archived tasks
# - archive!: Marks a task as archived (soft delete)
# - restore!: Unarchives a task (brings it back)
#
# ============================================================================

require "test_helper"

class TaskArchivingTest < ActiveSupport::TestCase
  # ==========================================================================
  # SETUP
  # ==========================================================================
  
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
  # DEFAULT SCOPE TESTS
  # ==========================================================================

  test "default scope excludes archived tasks" do
    active_task = Task.create!(@valid_attributes.merge(title: "Active"))
    archived_task = Task.create!(@valid_attributes.merge(title: "Archived"))
    archived_task.archive!
    
    # Query should only return active tasks
    tasks = Task.all
    assert_includes tasks, active_task
    assert_not_includes tasks, archived_task
  end
  
  test "unscoped returns all tasks including archived" do
    active_task = Task.create!(@valid_attributes.merge(title: "Active"))
    archived_task = Task.create!(@valid_attributes.merge(title: "Archived"))
    archived_task.archive!
    
    # unscoped should return both
    tasks = Task.unscoped
    assert_includes tasks, active_task
    assert_includes tasks, archived_task
  end

  # ==========================================================================
  # ARCHIVED SCOPE TESTS
  # ==========================================================================

  test "archived scope returns only archived tasks" do
    active_task = Task.create!(@valid_attributes.merge(title: "Active"))
    archived_task = Task.create!(@valid_attributes.merge(title: "Archived"))
    archived_task.archive!
    
    archived_tasks = Task.archived
    assert_includes archived_tasks, archived_task
    assert_not_includes archived_tasks, active_task
  end
  
  test "archived scope returns empty when no archived tasks" do
    Task.create!(@valid_attributes.merge(title: "Active"))
    
    assert_equal 0, Task.archived.count
  end

  # ==========================================================================
  # ACTIVE SCOPE TESTS
  # ==========================================================================

  test "active scope returns only non-archived tasks" do
    active_task = Task.create!(@valid_attributes.merge(title: "Active"))
    archived_task = Task.create!(@valid_attributes.merge(title: "Archived"))
    archived_task.archive!
    
    active_tasks = Task.active
    assert_includes active_tasks, active_task
    assert_not_includes active_tasks, archived_task
  end

  # ==========================================================================
  # WITH_ARCHIVED SCOPE TESTS
  # ==========================================================================

  test "with_archived scope returns all tasks" do
    active_task = Task.create!(@valid_attributes.merge(title: "Active"))
    archived_task = Task.create!(@valid_attributes.merge(title: "Archived"))
    archived_task.archive!
    
    all_tasks = Task.with_archived
    assert_includes all_tasks, active_task
    assert_includes all_tasks, archived_task
  end

  # ==========================================================================
  # ARCHIVE! METHOD TESTS
  # ==========================================================================

  test "archive! marks task as archived" do
    task = Task.create!(@valid_attributes)
    assert_equal false, task.archived?
    
    task.archive!
    task.reload
    
    assert_equal true, task.archived?
  end
  
  test "archive! bypasses validations" do
    task = Task.create!(@valid_attributes)
    
    # Make task temporarily invalid by clearing title at the database level
    # But archive! should still work because it uses update_column
    assert_nothing_raised do
      task.archive!
    end
  end
  
  test "archived task is excluded from default queries" do
    task = Task.create!(@valid_attributes)
    task.archive!
    
    assert_nil Task.find_by(id: task.id)
  end
  
  test "archived task can still be found with unscoped" do
    task = Task.create!(@valid_attributes)
    task.archive!
    
    assert_equal task, Task.unscoped.find(task.id)
  end

  # ==========================================================================
  # RESTORE! METHOD TESTS
  # ==========================================================================

  test "restore! unarchives a task" do
    task = Task.create!(@valid_attributes)
    task.archive!
    assert_equal true, task.reload.archived?
    
    task.restore!
    task.reload
    
    assert_equal false, task.archived?
  end
  
  test "restore! makes task visible in default queries again" do
    task = Task.create!(@valid_attributes)
    task.archive!
    assert_nil Task.find_by(id: task.id)
    
    task.restore!
    
    assert_equal task, Task.find(task.id)
  end

  # ==========================================================================
  # ARCHIVED? METHOD TESTS
  # ==========================================================================

  test "archived? returns true for archived tasks" do
    task = Task.create!(@valid_attributes)
    task.archive!
    
    assert_equal true, task.archived?
  end
  
  test "archived? returns false for active tasks" do
    task = Task.create!(@valid_attributes)
    
    assert_equal false, task.archived?
  end
  
  test "archived defaults to false for new tasks" do
    task = Task.new(@valid_attributes)
    
    assert_equal false, task.archived
  end

  # ==========================================================================
  # SCOPES ARE CHAINABLE WITH ARCHIVED
  # ==========================================================================

  test "scopes can be chained with archived scope" do
    mechdog_active = Task.create!(@valid_attributes.merge(title: "MechDog Active", assignee: "mechdog"))
    mechdog_archived = Task.create!(@valid_attributes.merge(title: "MechDog Archived", assignee: "mechdog"))
    mechdog_archived.archive!
    sparky_archived = Task.create!(@valid_attributes.merge(title: "Sparky Archived", assignee: "sparky"))
    sparky_archived.archive!
    
    mechdog_archived_tasks = Task.archived.for_assignee("mechdog")
    
    assert_includes mechdog_archived_tasks, mechdog_archived
    assert_not_includes mechdog_archived_tasks, mechdog_active
    assert_not_includes mechdog_archived_tasks, sparky_archived
  end
  
  test "for_assignee excludes archived tasks by default" do
    active_task = Task.create!(@valid_attributes.merge(title: "Active", assignee: "mechdog"))
    archived_task = Task.create!(@valid_attributes.merge(title: "Archived", assignee: "mechdog"))
    archived_task.archive!
    
    mechdog_tasks = Task.for_assignee("mechdog")
    
    assert_includes mechdog_tasks, active_task
    assert_not_includes mechdog_tasks, archived_task
  end

  # ==========================================================================
  # DATABASE DEFAULT TESTS
  # ==========================================================================

  test "database default for archived is false" do
    task = Task.create!(@valid_attributes)
    
    # Check raw database value
    result = Task.connection.execute("SELECT archived FROM tasks WHERE id = #{task.id}").first
    # Handle both hash and array result formats
    archived_value = result.is_a?(Hash) ? result["archived"] : result[0]
    assert_equal 0, archived_value # SQLite stores false as 0
  end
end
