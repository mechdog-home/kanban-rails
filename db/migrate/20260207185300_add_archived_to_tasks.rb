# ============================================================================
# Migration: Add Archived Flag to Tasks
# ============================================================================
#
# LEARNING NOTES:
#
# This migration adds an 'archived' boolean column to the tasks table.
# Instead of permanently deleting tasks, we'll set archived=true to
# "soft delete" them. This allows recovery of accidentally deleted tasks
# and maintains a history of completed work.
#
# KEY CONCEPTS:
# - Soft deletion: Marking records as deleted without removing them
# - Default values: New records start as unarchived (archived: false)
# - Database indexes: Adding an index on archived for efficient filtering
#
# COMPARISON TO EXPRESS/SEQUELIZE:
# - Sequelize: queryInterface.addColumn('tasks', 'archived', ...)
# - Rails: add_column :tasks, :archived, :boolean, default: false
#
# ============================================================================

class AddArchivedToTasks < ActiveRecord::Migration[8.1]
  def change
    # Add archived boolean column with default false
    # This means new tasks are NOT archived by default
    add_column :tasks, :archived, :boolean, default: false, null: false

    # Add index for efficient querying of archived/non-archived tasks
    # This speeds up queries like Task.where(archived: false)
    add_index :tasks, :archived

    # Add a composite index for common queries that filter by both
    # archived status and assignee or status
    add_index :tasks, [:archived, :assignee]
    add_index :tasks, [:archived, :status]
  end
end
