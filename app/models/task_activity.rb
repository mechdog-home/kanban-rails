# ============================================================================
# Model: TaskActivity
# ============================================================================
#
# This model represents an activity/event in a task's lifecycle.
# It's used to build a history/audit log of what happened to a task.
#
# LEARNING NOTES:
# - This is an audit trail pattern - track changes for accountability
# - Each activity captures WHO did WHAT and WHEN
# - The changeset JSON field stores before/after values
#
# COMPARISON TO EXPRESS:
# - Similar to using a separate "logs" or "audits" collection in MongoDB
# - Or a separate table with Sequelize that tracks changes
#
# ============================================================================

class TaskActivity < ApplicationRecord
  # Include view helpers for time formatting
  include ActionView::Helpers::DateHelper

  # ==========================================================================
  # ASSOCIATIONS
  # ==========================================================================
  
  belongs_to :task
  belongs_to :user, optional: true  # Optional because some actions may be system/API
  
  # ==========================================================================
  # CONSTANTS
  # ==========================================================================
  
  # Valid activity types
  TYPES = %w[created updated status_changed assignee_changed priority_changed 
             title_changed description_changed deleted moved archived restored].freeze
  
  # ==========================================================================
  # VALIDATIONS
  # ==========================================================================
  
  validates :activity_type, presence: true, inclusion: { in: TYPES }
  validates :task, presence: true
  
  # ==========================================================================
  # SCOPES
  # ==========================================================================
  
  # Get activities for a specific task, newest first
  scope :for_task, ->(task_id) { where(task_id: task_id).order(created_at: :desc) }
  
  # Get recent activities across all tasks
  scope :recent, ->(limit = 20) { order(created_at: :desc).limit(limit) }
  
  # Filter by activity type
  scope :of_type, ->(type) { where(activity_type: type) }
  
  # Get activities from the last N days
  scope :recent_days, ->(days = 7) { where('created_at > ?', days.days.ago) }
  
  # ==========================================================================
  # INSTANCE METHODS
  # ==========================================================================
  
  # Check if this activity represents a creation
  def created?
    activity_type == 'created'
  end
  
  # Check if this activity represents a deletion
  def deleted?
    activity_type == 'deleted'
  end
  
  # Get the old value for a specific field from changeset
  def old_value(field)
    changeset&.dig(field.to_s, 'from')
  end
  
  # Get the new value for a specific field from changeset
  def new_value(field)
    changeset&.dig(field.to_s, 'to')
  end
  
  # Human-readable time ago
  def time_ago
    return 'just now' if created_at > 1.minute.ago
    time_ago_in_words(created_at) + ' ago'
  end
  
  # Get icon class for Bootstrap based on activity type
  def icon_class
    case activity_type
    when 'created'
      'bi-plus-circle text-success'
    when 'deleted'
      'bi-trash text-danger'
    when 'archived'
      'bi-archive text-warning'
    when 'restored'
      'bi-arrow-counterclockwise text-success'
    when 'status_changed'
      'bi-arrow-repeat text-primary'
    when 'assignee_changed'
      'bi-person text-info'
    when 'priority_changed'
      'bi-exclamation-triangle text-warning'
    when 'title_changed', 'description_changed'
      'bi-pencil text-secondary'
    when 'moved'
      'bi-arrows-move text-primary'
    else
      'bi-pencil text-secondary'
    end
  end
  
  # ==========================================================================
  # CLASS METHODS
  # ==========================================================================
  
  # Create a 'created' activity for a new task
  def self.log_creation(task, user = nil)
    create!(
      task: task,
      user: user,
      activity_type: 'created',
      description: "Task created with status '#{task.status}' and priority '#{task.priority}'"
    )
  end
  
  # Log an update activity with field changes
  def self.log_update(task, changes, user = nil)
    return if changes.empty?
    
    # Determine the primary activity type based on what changed
    activity_type = determine_activity_type(changes)
    
    # Build human-readable description
    description = build_description(changes)
    
    create!(
      task: task,
      user: user,
      activity_type: activity_type,
      description: description,
      changeset: changes_to_json(changes)
    )
  end
  
  # Log a deletion
  def self.log_deletion(task, user = nil)
    create!(
      task: task,
      user: user,
      activity_type: 'deleted',
      description: "Task '#{task.title}' was deleted"
    )
  end
  
  private
  
  # Determine the primary activity type from changes
  def self.determine_activity_type(changes)
    if changes.key?('status')
      'status_changed'
    elsif changes.key?('assignee')
      'assignee_changed'
    elsif changes.key?('priority')
      'priority_changed'
    elsif changes.key?('title')
      'title_changed'
    elsif changes.key?('description')
      'description_changed'
    else
      'updated'
    end
  end
  
  # Build a human-readable description of changes
  def self.build_description(changes)
    parts = []
    
    if changes.key?('status')
      parts << "Status changed from '#{changes['status'][0]}' to '#{changes['status'][1]}'"
    end
    
    if changes.key?('assignee')
      parts << "Assignee changed from '#{changes['assignee'][0]}' to '#{changes['assignee'][1]}'"
    end
    
    if changes.key?('priority')
      parts << "Priority changed from '#{changes['priority'][0]}' to '#{changes['priority'][1]}'"
    end
    
    if changes.key?('title')
      parts << "Title updated"
    end
    
    if changes.key?('description')
      parts << "Description updated"
    end
    
    parts.empty? ? 'Task updated' : parts.join(', ')
  end
  
  # Convert Rails changes hash to JSON-serializable format
  def self.changes_to_json(changes)
    changes.transform_values { |v| { 'from' => v[0], 'to' => v[1] } }
  end
end
