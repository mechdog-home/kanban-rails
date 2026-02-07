# ============================================================================
# Migration: Create QuickNotes Table
# ============================================================================
#
# LEARNING NOTES:
#
# Migrations are Rails' way of evolving the database schema over time.
# Each migration file has a timestamp prefix to ensure they run in order.
#
# This migration creates the quick_notes table with:
# - title: Short title for the note (required)
# - content: Longer text content (optional, for quick jots)
# - user_id: Optional association to the creator
# - timestamps: Rails magic for created_at and updated_at
#
# COMPARISON TO SEQUELIZE/MONGOOSE:
# - Sequelize: You'd define this in a model file + migration
# - Rails: Migrations are separate from models, allowing schema evolution
#
# RUNNING MIGRATIONS:
#   rails db:migrate        - Run pending migrations
#   rails db:rollback       - Undo last migration
#   rails db:migrate:status - Check migration status
#
# ============================================================================

class CreateQuickNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quick_notes do |t|
      # Title is required but not at DB level (enforced by model validation)
      # We use null: true here to allow model-level error messages
      t.string :title, null: false
      
      # Content is optional text field for longer notes
      t.text :content
      
      # Optional association to user (who created the note)
      # null: true allows anonymous/system-created notes
      # foreign_key: true adds database-level referential integrity
      t.references :user, null: true, foreign_key: true

      # Rails automatically adds:
      # t.datetime :created_at  - When record was first created
      # t.datetime :updated_at  - When record was last modified
      t.timestamps
    end
    
    # Add index on created_at for efficient sorting
    # We often want "most recent notes first"
    add_index :quick_notes, :created_at
    
    # Add index on updated_at for "recently modified" queries
    add_index :quick_notes, :updated_at
    
    # LEARNING NOTE: Indexes improve query performance but add storage
    # and slightly slow down writes. Add them for columns you frequently
    # ORDER BY or WHERE filter on.
  end
end
