# ============================================================================
# Migration: Add Role to Users
# ============================================================================
#
# LEARNING NOTES:
#
# Adds a role field for authorization levels:
# - user: Regular user, can manage their own tasks
# - admin: Can manage all tasks
# - super_admin: Can manage all tasks AND manage users
#
# Default is 'user' for new signups.
#
# ============================================================================

class AddRoleToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: 'user'
    add_index :users, :role
  end
end
