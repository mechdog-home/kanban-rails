# ============================================================================
# Controller: ApplicationController
# ============================================================================
#
# LEARNING NOTES:
#
# This is the base controller all other controllers inherit from.
# Put shared behavior here (authentication, authorization, etc.)
#
# KEY CONCEPTS:
# - Devise provides `authenticate_user!` for requiring login
# - Pundit provides `authorize` and `policy_scope` for authorization
# - `before_action` runs code before controller actions
#
# ============================================================================

class ApplicationController < ActionController::Base
  # Include Pundit for authorization
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # -------------------------------------------------------------------------
  # Pundit Error Handling
  # -------------------------------------------------------------------------
  #
  # LEARNING NOTE: When authorization fails, Pundit raises an error.
  # We catch it here and redirect with a flash message.
  
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
