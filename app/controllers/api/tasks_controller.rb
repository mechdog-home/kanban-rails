# ============================================================================
# API Controller: Api::TasksController
# ============================================================================
#
# LEARNING NOTES:
#
# This controller handles JSON API requests for tasks.
# It's in the Api namespace, so routes are prefixed with /api.
#
# KEY CONCEPTS:
# - Namespaced controllers live in subdirectories (app/controllers/api/)
# - They inherit from a base API controller for shared behavior
# - All responses are JSON (no HTML views)
#
# API ENDPOINTS:
# - GET    /api/tasks          -> List tasks (with optional filters)
# - GET    /api/tasks/:id      -> Get single task
# - POST   /api/tasks          -> Create task
# - PATCH  /api/tasks/:id      -> Update task
# - DELETE /api/tasks/:id      -> Delete task
# - GET    /api/stats          -> Get task statistics (counts by assignee/status)
#
# COMPARISON TO EXPRESS/NODE.JS:
# - Express: app.get('/api/stats', (req, res) => { ... })
# - Rails:  def stats ... render json: stats end
# - Both use similar logic, but Rails organizes by controller action
#
# ============================================================================

module Api
  class TasksController < ApplicationController
    # Skip CSRF for API requests
    skip_before_action :verify_authenticity_token
    
    # Find task before show, update, destroy
    # Note: stats doesn't need set_task, so it's not in this list
    before_action :set_task, only: [:show, :update, :destroy]

    # ========================================================================
    # GET /api/stats
    # ========================================================================
    #
    # Returns summary statistics for the dashboard.
    # Matches the Node.js /api/stats endpoint format.
    #
    # Response format:
    # {
    #   "total": 42,
    #   "byAssignee": {
    #     "mechdog": 20,
    #     "sparky": 22
    #   },
    #   "byStatus": {
    #     "sprint": 5,
    #     "daily": 3,
    #     "backlog": 10,
    #     "in_progress": 8,
    #     "hold": 2,
    #     "done": 14
    #   }
    # }
    #
    # LEARNING NOTES:
    # - Rails uses ActiveRecord's count method for aggregation
    # - group(:column).count returns a hash: { 'value' => count }
    # - We use transform_keys to ensure consistent key types
    #
    # COMPARISON TO EXPRESS/NODE.JS:
    # - Express: db.prepare('SELECT COUNT(*)...').get().count
    # - Rails:  Task.count and Task.group(:status).count
    # - Rails abstracts the SQL, making it more readable
    #
    def stats
      # Build stats hash matching Node.js format
      stats = {
        total: Task.count,
        byAssignee: {
          mechdog: Task.for_assignee('mechdog').count,
          sparky: Task.for_assignee('sparky').count
        },
        byStatus: {
          sprint: Task.with_status('sprint').count,
          daily: Task.with_status('daily').count,
          backlog: Task.with_status('backlog').count,
          in_progress: Task.with_status('in_progress').count,
          hold: Task.with_status('hold').count,
          done: Task.with_status('done').count
        }
      }
      
      render json: stats
    end

    # ========================================================================
    # GET /api/tasks
    # ========================================================================
    #
    # Query parameters:
    # - assignee: Filter by assignee (e.g., ?assignee=sparky)
    # - status: Filter by status (e.g., ?status=backlog)
    #
    def index
      tasks = Task.all
      tasks = tasks.for_assignee(params[:assignee]) if params[:assignee].present?
      tasks = tasks.with_status(params[:status]) if params[:status].present?
      tasks = tasks.recent
      
      render json: tasks
    end

    # ========================================================================
    # GET /api/tasks/:id
    # ========================================================================
    def show
      render json: @task
    end

    # ========================================================================
    # POST /api/tasks
    # ========================================================================
    #
    # Request body:
    # {
    #   "title": "Task title",
    #   "description": "Optional",
    #   "assignee": "mechdog",
    #   "status": "backlog",
    #   "priority": "medium"
    # }
    #
    def create
      task = Task.new(task_params)
      
      if task.save
        render json: task, status: :created
      else
        render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # ========================================================================
    # PATCH /api/tasks/:id
    # ========================================================================
    def update
      if @task.update(task_params)
        render json: @task
      else
        render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # ========================================================================
    # DELETE /api/tasks/:id
    # ========================================================================
    def destroy
      @task.destroy
      head :no_content
    end

    private

    def set_task
      @task = Task.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Task not found' }, status: :not_found
    end

    def task_params
      params.permit(:title, :description, :assignee, :status, :priority)
    end
  end
end
