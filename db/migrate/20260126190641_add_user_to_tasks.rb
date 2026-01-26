# ============================================================================
# Migration: Add User Reference to Tasks
# ============================================================================
#
# LEARNING NOTES:
#
# This adds a foreign key from tasks to users, tracking who created each task.
# We use `null: true` because:
# 1. Existing tasks may not have a user assigned
# 2. API-created tasks (from Sparky's heartbeat) may not have a user
#
# In production, you might want to require user_id and backfill existing records.
#
# ============================================================================

class AddUserToTasks < ActiveRecord::Migration[8.1]
  def change
    # Add user_id column with foreign key, allowing null values
    add_reference :tasks, :user, null: true, foreign_key: true
  end
end
