# ============================================================================
# Model: User
# ============================================================================
#
# LEARNING NOTES:
#
# User model handles authentication via Devise and owns tasks.
#
# KEY CONCEPTS:
# - Devise provides authentication (login, logout, password reset, etc.)
# - has_many :tasks creates the association to tasks this user created
# - The name field lets us display friendly names instead of emails
#
# DEVISE MODULES:
# - database_authenticatable: Stores encrypted password in DB
# - registerable: Users can sign up
# - recoverable: Password reset via email
# - rememberable: "Remember me" checkbox functionality
# - validatable: Email/password validations
#
# ============================================================================

class User < ApplicationRecord
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

  # -------------------------------------------------------------------------
  # Instance Methods
  # -------------------------------------------------------------------------

  # Display name for the UI - prefer name over email
  def display_name
    name.presence || email.split('@').first
  end
end
