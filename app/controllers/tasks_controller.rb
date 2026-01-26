# ============================================================================
# Controller: TasksController
# ============================================================================
#
# LEARNING NOTES:
#
# This controller handles all task-related HTTP requests.
# Controllers are the "C" in MVC - they coordinate models and views.
#
# KEY CONCEPTS:
# - Each public method corresponds to an action (route endpoint)
# - `before_action` filters run before specified actions
# - `respond_to` handles multiple formats (HTML, JSON)
# - Strong parameters prevent mass assignment vulnerabilities
# - Devise's `authenticate_user!` requires login for HTML views
# - Pundit's `authorize` checks policy permissions
#
# COMPARISON TO EXPRESS:
# - Express: You'd define route handlers in separate files
# - Rails: Controllers group related actions, routes are in routes.rb
#
# API ENDPOINTS:
# - GET    /tasks          -> index (list all tasks)
# - GET    /tasks/:id      -> show (single task)
# - POST   /tasks          -> create (new task)
# - PATCH  /tasks/:id      -> update (modify task)
# - DELETE /tasks/:id      -> destroy (remove task)
#
# AUTHENTICATION:
# - HTML requests require login (Devise)
# - JSON API requests are open (for Sparky's heartbeat checks)
#   In production, add API token auth for JSON endpoints
#
# ============================================================================

class TasksController < ApplicationController
  # Skip CSRF verification for API requests (JSON)
  # In production, you'd use token-based auth instead
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }
  
  # Require login for HTML views, but allow JSON API access
  before_action :authenticate_user!, unless: -> { request.format.json? }
  
  # Find the task before show, update, and destroy actions
  before_action :set_task, only: [:show, :edit, :update, :destroy]
  
  # Authorize with Pundit (for HTML requests with a logged-in user)
  after_action :verify_authorized, except: :index, unless: -> { request.format.json? }
  after_action :verify_policy_scoped, only: :index, unless: -> { request.format.json? }

  # ==========================================================================
  # GET /tasks
  # ==========================================================================
  #
  # List all tasks, optionally filtered by assignee or status.
  # Supports both HTML (Kanban board view) and JSON (API).
  #
  # Query parameters:
  # - assignee: Filter by assignee (e.g., ?assignee=sparky)
  # - status: Filter by status (e.g., ?status=in_progress)
  #
  def index
    # Use Pundit scope for HTML (authorized records only)
    # Use all tasks for JSON API
    @tasks = if request.format.json?
               Task.all
             else
               policy_scope(Task)
             end
    
    # Apply filters if provided
    @tasks = @tasks.for_assignee(params[:assignee]) if params[:assignee].present?
    @tasks = @tasks.with_status(params[:status]) if params[:status].present?
    
    # Order by most recently updated
    @tasks = @tasks.recent
    
    respond_to do |format|
      format.html # Renders app/views/tasks/index.html.slim
      format.json { render json: @tasks }
    end
  end

  # ==========================================================================
  # GET /tasks/:id
  # ==========================================================================
  #
  # Show a single task.
  #
  def show
    authorize @task unless request.format.json?
    
    respond_to do |format|
      format.html # Renders app/views/tasks/show.html.slim
      format.json { render json: @task }
    end
  end

  # ==========================================================================
  # GET /tasks/new
  # ==========================================================================
  #
  # Show form for creating a new task (HTML only).
  #
  def new
    @task = Task.new
    authorize @task
  end

  # ==========================================================================
  # GET /tasks/:id/edit
  # ==========================================================================
  #
  # Show form for editing an existing task (HTML only).
  #
  def edit
    authorize @task
  end

  # ==========================================================================
  # POST /tasks
  # ==========================================================================
  #
  # Create a new task.
  #
  # Request body (JSON):
  # {
  #   "title": "Task title",
  #   "description": "Optional description",
  #   "assignee": "mechdog" or "sparky",
  #   "status": "backlog" (default),
  #   "priority": "medium" (default)
  # }
  #
  def create
    @task = Task.new(task_params)
    
    # Associate task with current user if logged in
    @task.user = current_user if current_user
    
    authorize @task unless request.format.json?
    
    respond_to do |format|
      if @task.save
        format.html { redirect_to tasks_path, notice: 'Task was successfully created.' }
        format.json { render json: @task, status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # ==========================================================================
  # PATCH/PUT /tasks/:id
  # ==========================================================================
  #
  # Update an existing task.
  #
  # Request body (JSON): Same as create, all fields optional
  #
  def update
    authorize @task unless request.format.json?
    
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to tasks_path, notice: 'Task was successfully updated.' }
        format.json { render json: @task }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # ==========================================================================
  # DELETE /tasks/:id
  # ==========================================================================
  #
  # Delete a task.
  #
  def destroy
    authorize @task unless request.format.json?
    
    @task.destroy
    
    respond_to do |format|
      format.html { redirect_to tasks_path, notice: 'Task was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  # ==========================================================================
  # PRIVATE METHODS
  # ==========================================================================
  
  private

  # Find task by ID from URL parameter
  # Called by before_action for show, edit, update, destroy
  def set_task
    @task = Task.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to tasks_path, alert: 'Task not found.' }
      format.json { render json: { error: 'Task not found' }, status: :not_found }
    end
  end

  # Strong parameters - only allow these attributes to be set
  #
  # LEARNING NOTE: This prevents mass assignment attacks.
  # Without this, a malicious user could set any attribute on the model.
  #
  # COMPARISON TO EXPRESS:
  # - Express: You'd manually pick properties from req.body
  # - Rails: Strong parameters provide a declarative whitelist
  #
  def task_params
    params.require(:task).permit(:title, :description, :assignee, :status, :priority)
  rescue ActionController::ParameterMissing
    # Allow params without :task wrapper for API convenience
    params.permit(:title, :description, :assignee, :status, :priority)
  end
end
