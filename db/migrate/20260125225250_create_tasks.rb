# ============================================================================
# Migration: Create Tasks Table
# ============================================================================
#
# LEARNING NOTES:
#
# This migration creates the tasks table for our Kanban board.
# Migrations are Ruby classes that modify the database schema.
#
# KEY CONCEPTS:
# - Migrations are version-controlled database changes
# - They run in order based on the timestamp in the filename
# - Use `rails db:migrate` to apply, `rails db:rollback` to undo
# - Always add default values for required fields when possible
#
# COMPARISON TO EXPRESS/KNEX:
# - Express: You'd write raw SQL or use Knex migrations
# - Rails: Provides a clean Ruby DSL that's database-agnostic
#
# ============================================================================

class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      # Title is required - the main task name
      t.string :title, null: false

      # Description is optional - additional details
      t.text :description

      # Assignee tracks who owns the task (e.g., "mechdog" or "sparky")
      t.string :assignee, null: false

      # Status tracks workflow state
      # Default to 'backlog' for new tasks
      t.string :status, null: false, default: 'backlog'

      # Priority helps with sorting/filtering
      # Default to 'medium' for new tasks
      t.string :priority, null: false, default: 'medium'

      # Rails automatically adds created_at and updated_at columns
      # These are updated automatically by ActiveRecord
      t.timestamps
    end

    # Add index on assignee for faster queries when filtering by person
    add_index :tasks, :assignee

    # Add index on status for faster queries when filtering by workflow state
    add_index :tasks, :status
  end
end
