# ============================================================================
# Controller: UsersController
# ============================================================================
#
# LEARNING NOTES:
#
# Handles user management. Only super_admin can access most actions.
# Regular users can only view/edit their own profile.
#
# KEY CONCEPTS:
# - Pundit's `authorize` checks policy before each action
# - `permitted_attributes` comes from the policy, not the controller
# - This keeps authorization logic centralized in policies
#
# ============================================================================

class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show, :edit, :update, :destroy]
  
  after_action :verify_authorized
  after_action :verify_policy_scoped, only: :index

  # ==========================================================================
  # GET /users
  # ==========================================================================
  #
  # List all users (super_admin only)
  #
  def index
    @users = policy_scope(User).order(:name)
    authorize User
  end

  # ==========================================================================
  # GET /users/:id
  # ==========================================================================
  #
  # Show user profile
  #
  def show
    authorize @user
  end

  # ==========================================================================
  # GET /users/new
  # ==========================================================================
  #
  # New user form (super_admin only)
  #
  def new
    @user = User.new
    authorize @user
  end

  # ==========================================================================
  # POST /users
  # ==========================================================================
  #
  # Create new user (super_admin only)
  #
  def create
    @user = User.new(user_params)
    authorize @user
    
    if @user.save
      redirect_to users_path, notice: "User '#{@user.name}' was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # ==========================================================================
  # GET /users/:id/edit
  # ==========================================================================
  #
  # Edit user form
  #
  def edit
    authorize @user
  end

  # ==========================================================================
  # PATCH/PUT /users/:id
  # ==========================================================================
  #
  # Update user
  #
  def update
    authorize @user
    
    # Remove blank password params if not changing password
    params_to_use = user_params
    if params_to_use[:password].blank?
      params_to_use = params_to_use.except(:password, :password_confirmation)
    end
    
    if @user.update(params_to_use)
      redirect_to users_path, notice: "User '#{@user.name}' was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # ==========================================================================
  # DELETE /users/:id
  # ==========================================================================
  #
  # Delete user (super_admin only, can't delete self)
  #
  def destroy
    authorize @user
    
    name = @user.name
    @user.destroy
    redirect_to users_path, notice: "User '#{name}' was successfully deleted."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  # Use permitted_attributes from policy
  def user_params
    params.require(:user).permit(policy(@user || User.new).permitted_attributes)
  end
end
