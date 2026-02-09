# ============================================================================
# Migration: CreateTaskAttachments
# ============================================================================
#
# Creates the task_attachments table for storing file metadata.
# Actual file content is stored via ActiveStorage.
#
# ============================================================================

class CreateTaskAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :task_attachments do |t|
      # Foreign key to tasks table
      t.references :task, null: false, foreign_key: true
      
      # Optional description/caption for the file
      t.text :description
      
      # Content type (redundant with ActiveStorage but useful for queries)
      t.string :content_type
      
      # Who uploaded the file
      t.references :user, foreign_key: true, null: true
      
      t.timestamps
    end
    
    # Index for faster lookups by task
    add_index :task_attachments, [:task_id, :created_at]
  end
end
