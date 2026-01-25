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
#
# ============================================================================

module Api
  class TasksController < ApplicationController
    # Skip CSRF for API requests
    skip_before_action :verify_authenticity_token
    
    # Find task before show, update, destroy
    before_action :set_task, only: [:show, :update, :destroy]

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
