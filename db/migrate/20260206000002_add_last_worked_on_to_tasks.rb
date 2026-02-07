# ============================================================================
# Migration: Add last_worked_on to Tasks
# ============================================================================
#
# Adds a datetime field to track when Sparky last worked on a task.
# This helps identify dormant tasks that might need attention.
#
# ============================================================================

class AddLastWorkedOnToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :last_worked_on, :datetime
    add_index :tasks, :last_worked_on
  end
end
