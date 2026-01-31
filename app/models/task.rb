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
  # ==========================================================================
  # ASSOCIATIONS
  # ==========================================================================
  #
  # LEARNING NOTE: belongs_to creates the association to the user who created
  # this task. The `optional: true` allows tasks without a user (for migration
  # of existing data and API access).
  
  belongs_to :user, optional: true

  # ==========================================================================
  # CONSTANTS
  # ==========================================================================
  
  # Valid workflow statuses for a task
  # These match the columns on our Kanban board
  STATUSES = %w[sprint daily backlog in_progress hold done].freeze
  
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
end
