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

  # -------------------------------------------------------------------------
  # Devise: Permit additional parameters
  # -------------------------------------------------------------------------
  #
  # LEARNING NOTE: By default, Devise only permits email and password.
  # When you add custom fields (username, name), you must tell Devise
  # to allow them through. This is done with `configure_permitted_parameters`.
  #
  # - sign_up: fields allowed when creating an account
  # - sign_in: fields allowed when logging in (login = email or username)
  # - account_update: fields allowed when editing profile
  
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:username, :name])
    devise_parameter_sanitizer.permit(:sign_in, keys: [:login])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, :name])
  end

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
