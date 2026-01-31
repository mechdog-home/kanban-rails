# ============================================================================
# Policy: TaskPolicy
# ============================================================================
#
# LEARNING NOTES:
#
# Pundit policies define authorization rules - who can do what.
# Each action in the controller gets a corresponding policy method.
#
# KEY CONCEPTS:
# - Policy methods return true/false for authorization
# - `record` is the object being authorized (a Task)
# - `user` is the current_user from Devise
# - Scope class defines which records a user can see
#
# COMPARISON TO EXPRESS:
# - Express: Middleware functions that check permissions
# - Rails/Pundit: Clean, testable policy classes
#
# ============================================================================

class TaskPolicy < ApplicationPolicy
  # -------------------------------------------------------------------------
  # Action Policies
  # -------------------------------------------------------------------------

  # Can the user view the task list?
  def index?
    # Any logged-in user can see tasks
    user.present?
  end

  # Can the user view this specific task?
  def show?
    user.present?
  end

  # Can the user create new tasks?
  def create?
    user.present?
  end

  # Can the user edit this task?
  def update?
    # Users can update any task (Kanban is collaborative)
    # Change to `record.user == user` if you want ownership-only editing
    user.present?
  end

  # Can the user delete this task?
  def destroy?
    # Only the task creator can delete it
    # Or you could allow anyone: `user.present?`
    record.user == user || record.user.nil?
  end

  # Can the user move task left (to previous status)?
  def move_left?
    # Any logged-in user can move tasks
    user.present?
  end

  # Can the user move task right (to next status)?
  def move_right?
    # Any logged-in user can move tasks
    user.present?
  end

  # -------------------------------------------------------------------------
  # Scope: Which tasks can this user see?
  # -------------------------------------------------------------------------
  #
  # Used with `policy_scope(Task)` in controllers
  # Returns an ActiveRecord relation of allowed records
  #
  class Scope < ApplicationPolicy::Scope
    def resolve
      # All logged-in users can see all tasks (shared Kanban)
      # Change to `scope.where(user: user)` for private tasks
      scope.all
    end
  end
end
