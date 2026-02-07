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
  # Added :archive, :restore for soft deletion
  before_action :set_task, only: [:show, :edit, :update, :destroy, :move_left, :move_right]
  
  # Find task including archived for restore action
  before_action :set_task_with_archived, only: [:restore]
  
  # Authorize with Pundit (for HTML requests with a logged-in user)
  after_action :verify_authorized, except: [:index, :archived], unless: -> { request.format.json? }
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
    
    # Load recent quick notes for display on the kanban board
    # Only load for HTML format (kanban board view)
    @recent_quick_notes = QuickNote.recent_for_board(5) unless request.format.json?
    
    respond_to do |format|
      format.html # Renders app/views/tasks/index.html.slim
      format.json { render json: @tasks }
    end
  end

  # ==========================================================================
  # GET /tasks/:id
  # ==========================================================================
  #
  # Show a single task with activity history.
  #
  def show
    authorize @task unless request.format.json?
    
    # Load recent activities for the task detail view
    @activities = @task.recent_activities(20)
    
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
        # Log the creation activity
        @task.log_creation_activity(current_user)
        
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
        # Log the update activity with changes
        @task.log_update_activity(current_user)
        
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
  # Archive a task (soft delete).
  # Instead of permanently deleting, we set archived=true.
  # This allows recovery and maintains history.
  #
  def destroy
    authorize @task unless request.format.json?
    
    # Archive the task instead of destroying
    # This is "soft deletion" - the task still exists but is hidden from the main board
    @task.archive!
    
    # Log the archive activity
    TaskActivity.create!(
      task: @task,
      activity_type: 'archived',
      description: "Task archived by #{current_user&.username || 'system'}",
      user: current_user
    )
    
    respond_to do |format|
      format.html { redirect_to tasks_path, notice: 'Task was successfully archived.' }
      format.json { head :no_content }
      format.turbo_stream do
        render turbo_stream: [
          # Remove the task card from the board
          turbo_stream.remove(@task),
          # Update the archived count badge
          turbo_stream.replace("archived_count", partial: "tasks/archived_count")
        ]
      end
    end
  end

  # ==========================================================================
  # GET /tasks/archived
  # ==========================================================================
  #
  # List all archived tasks.
  # This is a separate view from the main kanban board.
  # Archived tasks are soft-deleted tasks that can be restored.
  #
  def archived
    # Use unscoped to bypass default scope and find archived tasks
    @tasks = Task.archived.recent
    
    # Apply filters if provided
    @tasks = @tasks.for_assignee(params[:assignee]) if params[:assignee].present?
    @tasks = @tasks.with_status(params[:status]) if params[:status].present?
    
    authorize Task unless request.format.json?
  end

  # ==========================================================================
  # POST /tasks/:id/restore
  # ==========================================================================
  #
  # Restore an archived task (unarchive).
  # Brings the task back to the main kanban board.
  #
  def restore
    authorize @task unless request.format.json?
    
    # Restore the task by unarchiving it
    @task.restore!
    
    # Log the restore activity
    TaskActivity.create!(
      task: @task,
      activity_type: 'restored',
      description: "Task restored by #{current_user&.username || 'system'}",
      user: current_user
    )
    
    respond_to do |format|
      format.html { redirect_to archived_tasks_path, notice: 'Task was successfully restored.' }
      format.json { render json: @task }
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
      # Log the status change
      @task.log_update_activity(current_user)
      
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
        # Turbo Stream error - just return success with no changes
        # The UI can detect no change occurred
        format.turbo_stream do
          render turbo_stream: []
        end
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
      # Log the status change
      @task.log_update_activity(current_user)
      
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
        # Turbo Stream error - just return success with no changes
        # The UI can detect no change occurred
        format.turbo_stream do
          render turbo_stream: []
        end
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
  
  # Find task including archived ones
  # Called by before_action for restore action
  def set_task_with_archived
    @task = Task.with_archived.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to archived_tasks_path, alert: 'Task not found.' }
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
    params.require(:task).permit(:title, :description, :assignee, :status, :priority, :last_worked_on)
  rescue ActionController::ParameterMissing
    # Allow params without :task wrapper for API convenience
    params.permit(:title, :description, :assignee, :status, :priority, :last_worked_on)
  end

  # ==========================================================================
  # Helper: Fetch API Balances for View
  # ==========================================================================
  #
  # This helper makes AI provider balances available to views.
  # It's called by the index view to render the balance section.
  #
  helper_method :fetch_api_balances
  def fetch_api_balances
    # Use cached balances from database if available and fresh (< 10 min old)
    latest = ApiBalanceHistory.latest_balances
    
    # If we have recent data, use it; otherwise query live
    if latest.values.any? { |v| v[:queried_at] && v[:queried_at] > 10.minutes.ago }
      # Transform to same format as live query
      latest.transform_values do |data|
        {
          success: data[:success],
          balance: data[:balance],
          currency: data[:currency],
          queried_at: data[:queried_at],
          supports_api: true
        }
      end
    else
      # Fall back to live query
      BalanceService.query_all
    end
  rescue => e
    Rails.logger.error("Error fetching API balances: #{e.message}")
    # Return empty hash on error - view will handle gracefully
    {}
  end

  # ==========================================================================
  # Helper: Fetch Sparky Status for View
  # ==========================================================================
  #
  # This helper makes Sparky status available to views.
  # It's called by the index view to render the status card.
  #
  # LIVE DATA STRATEGY:
  # - Task info comes from the database (always live)
  # - Context/model comes from usage-log.json, but we also check database
  #   activity to determine if Sparky is actually active
  # - Uses the most recent data between file and database
  #
  helper_method :fetch_sparky_status
  def fetch_sparky_status
    begin
      # ======================================================================
      # STEP 1: Get current task from database (always live)
      # ======================================================================
      sprint_task = Task.for_assignee('sparky').with_status('sprint').first
      in_progress_task = Task.for_assignee('sparky').with_status('in_progress').first
      
      current_task = nil
      task_status = 'idle'
      last_task_update = nil
      
      if sprint_task
        current_task = {
          id: sprint_task.id,
          title: sprint_task.title,
          description: sprint_task.description,
          status: sprint_task.status,
          priority: sprint_task.priority
        }
        task_status = 'sprint'
        last_task_update = sprint_task.updated_at
      elsif in_progress_task
        current_task = {
          id: in_progress_task.id,
          title: in_progress_task.title,
          description: in_progress_task.description,
          status: in_progress_task.status,
          priority: in_progress_task.priority
        }
        task_status = 'in_progress'
        last_task_update = in_progress_task.updated_at
      end
      
      # ======================================================================
      # STEP 2: Get usage data from file (may be stale)
      # ======================================================================
      log_path = Rails.root.join('..', 'memory', 'usage-log.json')
      file_data = { context_percent: 0, model: 'moonshot/kimi-k2.5', file_timestamp: nil }
      
      if File.exist?(log_path)
        data = JSON.parse(File.read(log_path))
        sessions = data['sessions'] || []
        last_session = sessions.last || {}
        file_data = {
          context_percent: last_session['context_pct'] || 0,
          model: last_session['model'] || 'moonshot/kimi-k2.5',
          file_timestamp: last_session['timestamp'] ? Time.parse(last_session['timestamp']) : nil
        }
      end
      
      # ======================================================================
      # STEP 3: Check database for ACTUAL recent activity
      # ======================================================================
      # Get the most recent update to any Sparky task
      sparky_task_update = Task.for_assignee('sparky').maximum(:updated_at)
      # Get the most recent update to any task
      any_task_update = Task.maximum(:updated_at)
      
      # Determine the most recent activity timestamp
      last_activity = [sparky_task_update, any_task_update, file_data[:file_timestamp]].compact.max
      
      # ======================================================================
      # STEP 4: Determine if Sparky is "active"
      # ======================================================================
      # Active if:
      # - Has a current sprint/in_progress task, OR
      # - Had database activity in the last 10 minutes, OR
      # - Had file activity in the last 10 minutes
      ten_minutes_ago = 10.minutes.ago
      is_active = current_task.present? || 
                  (last_activity && last_activity > ten_minutes_ago)
      
      # ======================================================================
      # STEP 5: Build status response with live data
      # ======================================================================
      # Warn if file data is stale (> 30 minutes old)
      data_stale = file_data[:file_timestamp].nil? || 
                   file_data[:file_timestamp] < 30.minutes.ago
      
      {
        timestamp: Time.current.iso8601,
        is_active: is_active,
        status: task_status,
        current_task: current_task,
        context_percent: file_data[:context_percent],
        context_approx: "#{(file_data[:context_percent] * 2560 / 100)}k", # ~256k context window
        model: file_data[:model],
        last_activity_at: last_activity&.iso8601,
        data_source: data_stale ? 'stale_file' : 'file',
        data_stale: data_stale,
        file_timestamp: file_data[:file_timestamp]&.iso8601
      }
    rescue => e
      Rails.logger.error("Error fetching Sparky status: #{e.message}")
      # Return default status on error
      {
        timestamp: Time.current.iso8601,
        is_active: false,
        status: 'idle',
        current_task: nil,
        context_percent: 0,
        context_approx: '0k',
        model: 'unknown',
        last_activity_at: nil,
        data_source: 'error',
        data_stale: true,
        file_timestamp: nil
      }
    end
  end
end
