# ============================================================================
# Model Tests: TaskActivity
# ============================================================================
#
# Tests for the TaskActivity model and its associations.
#
# ============================================================================

require "test_helper"

class TaskActivityTest < ActiveSupport::TestCase
  # ==========================================================================
  # SETUP
  # ==========================================================================

  setup do
    @task = Task.create!(
      title: "Test Task",
      description: "Test description",
      assignee: "mechdog",
      status: "backlog",
      priority: "medium"
    )
    
    @user = User.create!(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123",
      username: "testuser",
      name: "Test User",
      role: "user"
    )
  end

  # ==========================================================================
  # VALIDATION TESTS
  # ==========================================================================

  test "should be valid with valid attributes" do
    activity = TaskActivity.new(
      task: @task,
      activity_type: 'created',
      description: 'Task created'
    )
    assert activity.valid?
  end

  test "should require activity_type" do
    activity = TaskActivity.new(task: @task)
    assert_not activity.valid?
    assert_includes activity.errors[:activity_type], "can't be blank"
  end

  test "should require valid activity_type" do
    activity = TaskActivity.new(
      task: @task,
      activity_type: 'invalid_type'
    )
    assert_not activity.valid?
    assert_includes activity.errors[:activity_type], "is not included in the list"
  end

  test "should require task" do
    activity = TaskActivity.new(activity_type: 'created')
    assert_not activity.valid?
    assert_includes activity.errors[:task], "must exist"
  end

  test "user should be optional" do
    activity = TaskActivity.new(
      task: @task,
      activity_type: 'created',
      description: 'Task created'
    )
    assert activity.valid?
    assert_nil activity.user
  end

  # ==========================================================================
  # ACTIVITY TYPE TESTS
  # ==========================================================================

  test "valid activity types" do
    valid_types = %w[created updated status_changed assignee_changed 
                     priority_changed title_changed description_changed deleted moved]
    
    valid_types.each do |type|
      activity = TaskActivity.new(
        task: @task,
        activity_type: type
      )
      assert activity.valid?, "#{type} should be a valid activity type"
    end
  end

  # ==========================================================================
  # INSTANCE METHOD TESTS
  # ==========================================================================

  test "created? returns true for created activities" do
    activity = TaskActivity.create!(
      task: @task,
      activity_type: 'created',
      description: 'Task created'
    )
    assert activity.created?
    assert_not activity.deleted?
  end

  test "deleted? returns true for deleted activities" do
    activity = TaskActivity.create!(
      task: @task,
      activity_type: 'deleted',
      description: 'Task deleted'
    )
    assert activity.deleted?
    assert_not activity.created?
  end

  test "old_value returns correct value from changeset" do
    activity = TaskActivity.create!(
      task: @task,
      activity_type: 'status_changed',
      changeset: { 'status' => { 'from' => 'backlog', 'to' => 'in_progress' } }
    )
    assert_equal 'backlog', activity.old_value('status')
    assert_equal 'in_progress', activity.new_value('status')
  end

  test "old_value returns nil for missing field" do
    activity = TaskActivity.create!(
      task: @task,
      activity_type: 'created'
    )
    assert_nil activity.old_value('status')
  end

  test "time_ago returns human readable time" do
    activity = TaskActivity.create!(
      task: @task,
      activity_type: 'created',
      created_at: 1.hour.ago
    )
    assert_includes activity.time_ago, 'hour'
  end

  test "icon_class returns correct icon for each activity type" do
    icons = {
      'created' => 'bi-plus-circle',
      'deleted' => 'bi-trash',
      'status_changed' => 'bi-arrow-repeat',
      'assignee_changed' => 'bi-person',
      'priority_changed' => 'bi-exclamation-triangle',
      'title_changed' => 'bi-pencil',
      'description_changed' => 'bi-pencil',
      'moved' => 'bi-arrows-move'
    }
    
    icons.each do |type, expected_icon|
      activity = TaskActivity.new(activity_type: type)
      assert_includes activity.icon_class, expected_icon, "#{type} should have #{expected_icon} icon"
    end
  end

  # ==========================================================================
  # SCOPE TESTS
  # ==========================================================================

  test "for_task scope returns activities for specific task" do
    other_task = Task.create!(
      title: "Other Task",
      assignee: "sparky",
      status: "backlog",
      priority: "low"
    )
    
    activity1 = TaskActivity.create!(task: @task, activity_type: 'created')
    activity2 = TaskActivity.create!(task: other_task, activity_type: 'created')
    
    results = TaskActivity.for_task(@task.id)
    assert_includes results, activity1
    assert_not_includes results, activity2
  end

  test "for_task returns activities in descending order" do
    activity1 = TaskActivity.create!(task: @task, activity_type: 'created', created_at: 2.hours.ago)
    activity2 = TaskActivity.create!(task: @task, activity_type: 'updated', created_at: 1.hour.ago)
    activity3 = TaskActivity.create!(task: @task, activity_type: 'updated', created_at: 30.minutes.ago)
    
    results = TaskActivity.for_task(@task.id)
    assert_equal [activity3, activity2, activity1], results.to_a
  end

  test "recent scope returns limited number of activities" do
    5.times do |i|
      TaskActivity.create!(task: @task, activity_type: 'created', created_at: i.minutes.ago)
    end
    
    assert_equal 3, TaskActivity.recent(3).count
    assert_equal 5, TaskActivity.recent(10).count
  end

  test "of_type scope filters by activity type" do
    TaskActivity.create!(task: @task, activity_type: 'created')
    TaskActivity.create!(task: @task, activity_type: 'updated')
    TaskActivity.create!(task: @task, activity_type: 'updated')
    
    assert_equal 2, TaskActivity.of_type('updated').count
  end

  test "recent_days scope returns activities from last N days" do
    TaskActivity.create!(task: @task, activity_type: 'created', created_at: 1.day.ago)
    TaskActivity.create!(task: @task, activity_type: 'updated', created_at: 10.days.ago)
    
    assert_equal 1, TaskActivity.recent_days(7).count
  end

  # ==========================================================================
  # CLASS METHOD TESTS - Logging
  # ==========================================================================

  test "log_creation creates created activity" do
    new_task = Task.create!(
      title: "New Task",
      assignee: "mechdog",
      status: "backlog",
      priority: "high"
    )
    
    activity = TaskActivity.log_creation(new_task, @user)
    
    assert_equal 'created', activity.activity_type
    assert_equal new_task, activity.task
    assert_equal @user, activity.user
    assert_includes activity.description, 'created'
    assert_includes activity.description, 'backlog'
    assert_includes activity.description, 'high'
  end

  test "log_update creates activity with changeset" do
    changes = { 'status' => ['backlog', 'in_progress'] }
    
    activity = TaskActivity.log_update(@task, changes, @user)
    
    assert_equal 'status_changed', activity.activity_type
    assert_equal @task, activity.task
    assert_equal @user, activity.user
    assert_includes activity.description, 'Status changed'
    assert_equal 'backlog', activity.changeset['status']['from']
    assert_equal 'in_progress', activity.changeset['status']['to']
  end

  test "log_update returns nil for empty changes" do
    activity = TaskActivity.log_update(@task, {}, @user)
    assert_nil activity
  end

  test "log_update determines correct activity type for assignee change" do
    changes = { 'assignee' => ['mechdog', 'sparky'] }
    activity = TaskActivity.log_update(@task, changes, @user)
    
    assert_equal 'assignee_changed', activity.activity_type
    assert_includes activity.description, 'Assignee changed'
  end

  test "log_update determines correct activity type for priority change" do
    changes = { 'priority' => ['medium', 'high'] }
    activity = TaskActivity.log_update(@task, changes, @user)
    
    assert_equal 'priority_changed', activity.activity_type
    assert_includes activity.description, 'Priority changed'
  end

  test "log_update handles multiple changes" do
    changes = { 
      'status' => ['backlog', 'in_progress'],
      'priority' => ['medium', 'high']
    }
    activity = TaskActivity.log_update(@task, changes, @user)
    
    assert_equal 'status_changed', activity.activity_type  # status takes priority
    assert_includes activity.description, 'Status changed'
    assert_includes activity.description, 'Priority changed'
  end

  test "log_deletion creates deleted activity" do
    activity = TaskActivity.log_deletion(@task, @user)
    
    assert_equal 'deleted', activity.activity_type
    assert_equal @task, activity.task
    assert_equal @user, activity.user
    assert_includes activity.description, @task.title
    assert_includes activity.description, 'deleted'
  end
end
