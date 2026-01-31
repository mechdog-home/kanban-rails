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
  # Added :move_left and :move_right for status transitions
  before_action :set_task, only: [:show, :edit, :update, :destroy, :move_left, :move_right]
  
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
  # POST /tasks/:id/move_left
  # ==========================================================================
  #
  # Move task to previous status in workflow.
  # Used by left arrow button on task cards.
  #
  # LEARNING NOTES - RAILS AJAX PATTERNS:
  # -------------------------------------
  # Rails has multiple ways to handle AJAX:
  #
  # 1. RAILS UJS (Unobtrusive JavaScript):
  #    - Add data: { turbo: true } to link_to or button_to
  #    - Rails automatically converts to AJAX
  #    - Response is a Turbo Stream that updates the page
  #
  # 2. TURBO FRAMES:
  #    - Wrap content in <%= turbo_frame_tag ... %>
  #    - Links/forms within frame update just that frame
  #
  # 3. TURBO STREAMS (used here):
  #    - Controller returns turbo_stream responses
  #    - Server sends HTML fragments, Turbo updates DOM
  #
  # COMPARISON TO NODE.JS/FETCH:
  # ----------------------------
  # Express/Vanilla approach:
  #   fetch(`/api/tasks/${id}`, { method: 'PUT', body: JSON.stringify({status}) })
  #     .then(res => res.json())
  #     .then(data => {
  #       // Manually update DOM
  #       document.getElementById(`task-${id}`).remove()
  #       // Add to new column...
  #     })
  #
  # Rails/Turbo approach:
  #   button_to '←', move_left_task_path(task), method: :post
  #   // Controller returns turbo_stream.replace ...
  #   // Turbo automatically updates the DOM - no JS needed!
  #
  def move_left
    authorize @task unless request.format.json?
    
    previous = @task.previous_status
    
    if previous && @task.update(status: previous)
      respond_to do |format|
        # Turbo Stream response - updates the page automatically
        format.turbo_stream do
          render turbo_stream: [
            # Remove task from current column
            turbo_stream.remove(@task),
            # Add task to new column (at the top)
            turbo_stream.prepend(
              "column_#{@task.assignee}_#{@task.status}",
              partial: 'tasks/task_card',
              locals: { task: @task }
            ),
            # Update column counts
            turbo_stream.update(
              "count_#{@task.assignee}_#{@task.status}",
              Task.for_assignee(@task.assignee).with_status(@task.status).count.to_s
            ),
            turbo_stream.update(
              "count_#{@task.assignee}_#{previous}",
              Task.for_assignee(@task.assignee).with_status(previous).count.to_s
            )
          ]
        end
        format.html { redirect_to tasks_path, notice: 'Task moved.' }
        format.json { render json: @task }
      end
    else
      respond_to do |format|
        format.html { redirect_to tasks_path, alert: 'Cannot move task further left.' }
        format.json { render json: { error: 'Cannot move task further left' }, status: :unprocessable_entity }
      end
    end
  end

  # ==========================================================================
  # POST /tasks/:id/move_right
  # ==========================================================================
  #
  # Move task to next status in workflow.
  # Used by right arrow button on task cards.
  #
  def move_right
    authorize @task unless request.format.json?
    
    next_stat = @task.next_status
    
    if next_stat && @task.update(status: next_stat)
      respond_to do |format|
        # Turbo Stream response - updates the page automatically
        format.turbo_stream do
          render turbo_stream: [
            # Remove task from current column
            turbo_stream.remove(@task),
            # Add task to new column (at the top)
            turbo_stream.prepend(
              "column_#{@task.assignee}_#{@task.status}",
              partial: 'tasks/task_card',
              locals: { task: @task }
            ),
            # Update column counts
            turbo_stream.update(
              "count_#{@task.assignee}_#{@task.status}",
              Task.for_assignee(@task.assignee).with_status(@task.status).count.to_s
            ),
            turbo_stream.update(
              "count_#{@task.assignee}_#{next_stat}",
              Task.for_assignee(@task.assignee).with_status(next_stat).count.to_s
            )
          ]
        end
        format.html { redirect_to tasks_path, notice: 'Task moved.' }
        format.json { render json: @task }
      end
    else
      respond_to do |format|
        format.html { redirect_to tasks_path, alert: 'Cannot move task further right.' }
        format.json { render json: { error: 'Cannot move task further right' }, status: :unprocessable_entity }
      end
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
