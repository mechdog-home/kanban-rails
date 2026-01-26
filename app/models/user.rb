# ============================================================================
# Model: User
# ============================================================================
#
# LEARNING NOTES:
#
# User model handles authentication via Devise and authorization via roles.
#
# ROLES:
# - user: Regular user (default for new signups)
# - admin: Can manage all tasks
# - super_admin: Full access, can manage users
#
# KEY CONCEPTS:
# - Devise provides authentication (login, logout, password reset, etc.)
# - Role field controls authorization level
# - Helper methods (super_admin?, admin?) make policy checks readable
#
# ============================================================================

class User < ApplicationRecord
  # -------------------------------------------------------------------------
  # Constants
  # -------------------------------------------------------------------------
  
  ROLES = %w[user admin super_admin].freeze

  # -------------------------------------------------------------------------
  # Devise Configuration
  # -------------------------------------------------------------------------
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # -------------------------------------------------------------------------
  # Associations
  # -------------------------------------------------------------------------

  # A user can create many tasks
  # dependent: :nullify means if user is deleted, tasks stay but user_id becomes nil
  has_many :tasks, dependent: :nullify

  # -------------------------------------------------------------------------
  # Validations
  # -------------------------------------------------------------------------

  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }

  # -------------------------------------------------------------------------
  # Role Helper Methods
  # -------------------------------------------------------------------------
  
  # Is this user a super admin? (full access)
  def super_admin?
    role == 'super_admin'
  end
  
  # Is this user an admin or higher?
  def admin?
    role.in?(%w[admin super_admin])
  end
  
  # Is this user a regular user?
  def regular_user?
    role == 'user'
  end

  # -------------------------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------------------------

  # Display name for the UI - prefer name over email
  def display_name
    name.presence || email.split('@').first
  end
  
  # Role badge for display
  def role_badge
    case role
    when 'super_admin' then 'Super Admin'
    when 'admin' then 'Admin'
    else 'User'
    end
  end
end
