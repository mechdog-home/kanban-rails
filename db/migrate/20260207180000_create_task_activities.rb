# ============================================================================
# Migration: Create Task Activities
# ============================================================================
#
# This migration creates the task_activities table for tracking task history.
# Each activity record represents an event in a task's lifecycle:
# - Created
# - Updated (with field changes)
# - Status changed
# - Assignee changed
# - etc.
#
# ============================================================================

class CreateTaskActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :task_activities do |t|
      # Reference to the task this activity belongs to
      t.references :task, null: false, foreign_key: true, index: true
      
      # The type of activity (created, updated, status_changed, etc.)
      t.string :activity_type, null: false, index: true
      
      # Description of what happened (human-readable)
      t.text :description
      
      # JSON field to store before/after values for field changes
      # Example: { "status": { "from": "backlog", "to": "in_progress" } }
      t.json :changeset, default: {}
      
      # User who performed the action (if known)
      t.references :user, null: true, foreign_key: true
      
      # Timestamps
      t.datetime :created_at, null: false
    end
    
    # Add index for querying task history efficiently
    add_index :task_activities, [:task_id, :created_at], order: { created_at: :desc }
  end
end
