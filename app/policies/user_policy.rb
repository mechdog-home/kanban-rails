# ============================================================================
# Policy: UserPolicy
# ============================================================================
#
# LEARNING NOTES:
#
# Controls who can manage users. Only super_admin can:
# - View user list
# - Create new users
# - Edit user roles/details
# - Delete users
#
# Regular users can only view/edit their own profile.
#
# ============================================================================

class UserPolicy < ApplicationPolicy
  # -------------------------------------------------------------------------
  # Action Policies
  # -------------------------------------------------------------------------

  # Can view the list of users?
  def index?
    user.super_admin?
  end

  # Can view this user's profile?
  def show?
    user.super_admin? || record == user
  end

  # Can create new users?
  def create?
    user.super_admin?
  end
  
  # Alias for create (new form)
  def new?
    create?
  end

  # Can edit this user?
  def update?
    user.super_admin? || record == user
  end
  
  # Alias for update (edit form)
  def edit?
    update?
  end

  # Can delete this user?
  def destroy?
    # Super admin can delete anyone except themselves
    user.super_admin? && record != user
  end
  
  # Can change user's role?
  def change_role?
    user.super_admin?
  end

  # -------------------------------------------------------------------------
  # Scope: Which users can this user see?
  # -------------------------------------------------------------------------
  
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.super_admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
  
  # -------------------------------------------------------------------------
  # Permitted Attributes
  # -------------------------------------------------------------------------
  #
  # LEARNING NOTE: Pundit can also control which attributes are permitted.
  # This is cleaner than putting logic in the controller.
  
  def permitted_attributes
    if user.super_admin?
      [:name, :email, :password, :password_confirmation, :role]
    else
      [:name, :email, :password, :password_confirmation]
    end
  end
end
