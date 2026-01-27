# ============================================================================
# Model: User
# ============================================================================
#
# LEARNING NOTES:
#
# User model handles authentication via Devise and authorization via roles.
#
# LOGIN FLEXIBILITY:
# - Users can sign in with either their email OR username
# - This is done via a virtual attribute called `login`
# - Devise's `find_for_database_authentication` is overridden to check both
# - The `authentication_keys` config in devise.rb is set to [:login]
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
  # Virtual Attributes
  # -------------------------------------------------------------------------

  # `login` is a virtual attribute — it doesn't exist in the database.
  # It lets users type either their email or username into the login field.
  # Devise uses it via authentication_keys: [:login]
  attr_accessor :login

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
  validates :username, presence: true,
                       uniqueness: { case_sensitive: false },
                       length: { minimum: 3, maximum: 30 },
                       format: { with: /\A[a-zA-Z0-9_]+\z/,
                                 message: "only allows letters, numbers, and underscores" }
  validates :role, presence: true, inclusion: { in: ROLES }

  # -------------------------------------------------------------------------
  # Devise: Allow login by email OR username
  # -------------------------------------------------------------------------

  # Override Devise's lookup method to find users by email or username.
  # This is called when a user submits the login form.
  # If the value looks like an email, search by email; otherwise by username.
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    login = conditions.delete(:login)

    if login.present?
      # Case-insensitive search on both email and username
      where("LOWER(email) = :value OR LOWER(username) = :value",
            value: login.strip.downcase).first
    elsif conditions.has_key?(:email)
      where(email: conditions[:email]).first
    elsif conditions.has_key?(:username)
      where(username: conditions[:username]).first
    end
  end

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

  # Display name for the UI - prefer name, then username, then email
  def display_name
    name.presence || username.presence || email.split('@').first
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
