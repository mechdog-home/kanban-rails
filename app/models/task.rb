# ============================================================================
# Model: Task
# ============================================================================
#
# LEARNING NOTES:
#
# This is an ActiveRecord model representing a task on our Kanban board.
# Models are the "M" in MVC - they handle data and business logic.
#
# KEY CONCEPTS:
# - ActiveRecord is Rails' ORM (Object-Relational Mapping)
# - Models inherit from ApplicationRecord (which inherits from ActiveRecord::Base)
# - Validations ensure data integrity before saving to the database
# - Scopes provide reusable query fragments
#
# COMPARISON TO EXPRESS/SEQUELIZE:
# - Express: You'd define a model with Sequelize or mongoose
# - Rails: Models are simpler, more convention-based
#
# CONVENTIONS (per RAILS_CONVENTIONS.md):
# - Use full model names, no abbreviations (e.g., `task` not `t`)
# - Validations protect data integrity at the application level
#
# ============================================================================

class Task < ApplicationRecord
  # Include view helpers for time formatting
  include ActionView::Helpers::DateHelper

  # ==========================================================================
  # CALLBACKS
  # ==========================================================================
  #
  # Update last_worked_on when task is modified (if it was a meaningful change)
  after_update :touch_last_worked_if_status_changed
  
  # Track activities for audit trail
  # after_create :log_creation_activity
  # after_update :log_update_activity
  # after_destroy :log_deletion_activity
  
  # ==========================================================================
  # ASSOCIATIONS
  # ==========================================================================
  #
  # LEARNING NOTE: belongs_to creates the association to the user who created
  # this task. The `optional: true` allows tasks without a user (for migration
  # of existing data and API access).
  
  belongs_to :user, optional: true
  
  # Task has many activities (audit trail)
  # dependent: :destroy ensures activities are deleted when task is deleted
  has_many :activities, class_name: 'TaskActivity', dependent: :destroy

  # ==========================================================================
  # CONSTANTS
  # ==========================================================================
  
  # Valid workflow statuses for a task
  # These match the columns on our Kanban board
  # Order matters for next_status/previous_status methods!
  STATUSES = %w[hold backlog in_progress sprint daily done].freeze
  
  # Valid priority levels
  PRIORITIES = %w[low medium high urgent].freeze
  
  # Valid assignees (can be extended or made dynamic later)
  ASSIGNEES = %w[mechdog sparky].freeze

  # ==========================================================================
  # VALIDATIONS
  # ==========================================================================
  #
  # LEARNING NOTE: Validations run before save/create/update.
  # If they fail, the record won't be saved and errors are added.
  # Check with: task.valid? and task.errors.full_messages
  
  # Title is required
  validates :title, presence: true
  
  # Assignee must be one of the valid options
  validates :assignee, presence: true, inclusion: { in: ASSIGNEES }
  
  # Status must be one of the valid workflow states
  validates :status, presence: true, inclusion: { in: STATUSES }
  
  # Priority must be one of the valid levels
  validates :priority, presence: true, inclusion: { in: PRIORITIES }

  # ==========================================================================
  # SCOPES
  # ==========================================================================
  #
  # LEARNING NOTE: Scopes are reusable query fragments.
  # They return ActiveRecord::Relation objects, so they're chainable.
  # Example: Task.for_assignee('sparky').in_progress
  
  # Filter tasks by assignee
  # Usage: Task.for_assignee('mechdog')
  scope :for_assignee, ->(assignee) { where(assignee: assignee) }
  
  # Filter tasks by status
  # Usage: Task.with_status('in_progress')
  scope :with_status, ->(status) { where(status: status) }
  
  # Filter tasks by priority
  # Usage: Task.with_priority('high')
  scope :with_priority, ->(priority) { where(priority: priority) }
  
  # ==========================================================================
  # ARCHIVED SCOPES (Soft Deletion)
  # ==========================================================================
  #
  # LEARNING NOTE: Instead of permanently deleting tasks, we "archive" them.
  # This is called "soft deletion" and provides several benefits:
  # - Recovery of accidentally deleted tasks
  # - Historical record of all work
  # - Ability to review and restore old tasks
  #
  # The default scope excludes archived tasks so the main board stays clean.
  
  # Default scope: exclude archived tasks from all queries
  # This ensures archived tasks don't appear on the main kanban board
  default_scope { where(archived: false) }
  
  # Scope to show only archived (soft-deleted) tasks
  # Usage: Task.archived
  scope :archived, -> { unscoped.where(archived: true) }
  
  # Scope to show only active (non-archived) tasks
  # Usage: Task.active (same as default, but explicit)
  scope :active, -> { where(archived: false) }
  
  # Scope to include both archived and active (bypass default scope)
  # Usage: Task.with_archived
  scope :with_archived, -> { unscoped }
  
  # Get tasks in sprint (priority queue)
  scope :sprint, -> { with_status('sprint') }
  
  # Get daily tasks
  scope :daily, -> { with_status('daily') }
  
  # Get tasks in backlog
  scope :backlog, -> { with_status('backlog') }
  
  # Get tasks in progress
  scope :in_progress, -> { with_status('in_progress') }
  
  # Get tasks on hold
  scope :hold, -> { with_status('hold') }
  
  # Get completed tasks
  scope :done, -> { with_status('done') }
  
  # Order by most recently updated
  scope :recent, -> { order(updated_at: :desc) }
  
  # Order by priority (urgent first, then high, medium, low)
  scope :by_priority, -> {
    order(Arel.sql("FIELD(priority, 'urgent', 'high', 'medium', 'low')"))
  }
  
  # Order by last worked on (most recent first)
  scope :by_last_worked, -> { order(last_worked_on: :desc) }
  
  # Find dormant tasks (not worked on in last 7 days)
  scope :dormant, -> { where('last_worked_on < ? OR last_worked_on IS NULL', 7.days.ago) }

  # ==========================================================================
  # CLASS METHODS
  # ==========================================================================
  
  # Get all tasks grouped by status (useful for Kanban board display)
  # Returns: { 'backlog' => [...], 'in_progress' => [...], ... }
  def self.grouped_by_status
    all.group_by(&:status)
  end
  
  # Get all tasks grouped by assignee
  # Returns: { 'mechdog' => [...], 'sparky' => [...] }
  def self.grouped_by_assignee
    all.group_by(&:assignee)
  end

  # ==========================================================================
  # INSTANCE METHODS
  # ==========================================================================
  
  # Check if task is completed
  def done?
    status == 'done'
  end
  
  # Check if task is in active work
  def in_progress?
    status == 'in_progress'
  end
  
  # Check if task is urgent
  def urgent?
    priority == 'urgent'
  end
  
  # Move task to next status in workflow (right arrow)
  def advance_status!
    current_index = STATUSES.index(status)
    return if current_index.nil? || current_index >= STATUSES.length - 1
    
    update!(status: STATUSES[current_index + 1])
  end
  
  # Move task to previous status in workflow (left arrow)
  def regress_status!
    current_index = STATUSES.index(status)
    return if current_index.nil? || current_index <= 0
    
    update!(status: STATUSES[current_index - 1])
  end
  
  # Get the next status without changing it
  def next_status
    current_index = STATUSES.index(status)
    return nil if current_index.nil? || current_index >= STATUSES.length - 1
    STATUSES[current_index + 1]
  end
  
  # Get the previous status without changing it
  def previous_status
    current_index = STATUSES.index(status)
    return nil if current_index.nil? || current_index <= 0
    STATUSES[current_index - 1]
  end
  
  # ==========================================================================
  # ARCHIVE/RESTORE METHODS (Soft Deletion)
  # ==========================================================================
  
  # Archive this task (soft delete)
  # Instead of destroying the record, we mark it as archived
  # This allows recovery and maintains history
  def archive!
    update_column(:archived, true)
  end
  
  # Restore this task from archive (unarchive)
  # Makes the task visible on the main kanban board again
  def restore!
    update_column(:archived, false)
  end
  
  # Check if this task is archived
  def archived?
    archived == true
  end

  # Update last_worked_on timestamp when Sparky works on this task
  def touch_last_worked!
    update_column(:last_worked_on, Time.current)
  end

  # Check if task is dormant (not worked on in last 7 days)
  def dormant?
    return false if last_worked_on.nil?
    last_worked_on < 7.days.ago
  end

  # Human-readable time since last work
  def time_since_work
    return "Never" if last_worked_on.nil?
    time_ago_in_words(last_worked_on) + " ago"
  end
  
  # ==========================================================================
  # ACTIVITY LOGGING METHODS
  # ==========================================================================
  #
  # These methods create activity records for the audit trail.
  # They're called by controller actions to track who made what changes.
  
  # Log task creation
  def log_creation_activity(user = nil)
    TaskActivity.log_creation(self, user)
  end
  
  # Log task update with field changes
  def log_update_activity(user = nil)
    # saved_changes is a Rails method that returns hash of changed fields
    # Format: { "field" => [old_value, new_value] }
    changes = saved_changes.slice('title', 'description', 'status', 'assignee', 'priority')
    TaskActivity.log_update(self, changes, user) if changes.any?
  end
  
  # Log task deletion (called before_destroy)
  def log_deletion_activity(user = nil)
    TaskActivity.log_deletion(self, user)
  end
  
  # Get recent activities for this task
  def recent_activities(limit = 50)
    activities.recent(limit)
  end
  
  private
  
  # Callback: Update last_worked_on when status or assignee changes
  def touch_last_worked_if_status_changed
    if saved_change_to_status? || saved_change_to_assignee?
      update_column(:last_worked_on, Time.current)
    end
  end
end
